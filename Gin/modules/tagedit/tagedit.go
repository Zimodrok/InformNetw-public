package tagedit

import (
	sftpTools "MusicAppGin/modules/SFTP"
	"database/sql"
	"encoding/base64"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/wtolson/go-taglib"
)

type MetadataUpdateRequest struct {
	Title       string `json:"title"`
	Artist      string `json:"artist"`
	Album       string `json:"album"`
	Genre       string `json:"genre"`
	Year        int    `json:"year"`
	Comment     string `json:"comment"`
	CoverBase64 string `json:"coverBase64"`
	CoverURL    string `json:"coverUrl"`
	Copyright   string `json:"copyright"`
}

func SetDB(d *sql.DB) { db = d }

func FetchImageAsBase64(url string) (string, error) {
	if strings.TrimSpace(url) == "" {
		return "", fmt.Errorf("empty url")
	}

	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("fetch cover: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return "", fmt.Errorf("cover http status: %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read cover: %w", err)
	}

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg"
	} else {
		if ct, _, err := mime.ParseMediaType(contentType); err == nil {
			contentType = ct
		}
	}

	b64 := base64.StdEncoding.EncodeToString(data)
	return fmt.Sprintf("data:%s;base64,%s", contentType, b64), nil
}

func embedCoverInFlac(flacPath string, dataURL string) error {
	if strings.TrimSpace(dataURL) == "" {
		return nil
	}
	// Expect data URL: data:<mime>;base64,<payload>
	parts := strings.SplitN(dataURL, ",", 2)
	if len(parts) != 2 {
		return fmt.Errorf("invalid data url")
	}
	payload := parts[1]
	mimeType := "image/jpeg"
	if strings.HasPrefix(parts[0], "data:") {
		if mt := strings.TrimPrefix(parts[0], "data:"); mt != "" {
			if semi := strings.Index(mt, ";"); semi != -1 {
				mt = mt[:semi]
			}
			if mt != "" {
				mimeType = mt
			}
		}
	}

	data, err := base64.StdEncoding.DecodeString(payload)
	if err != nil {
		return fmt.Errorf("decode cover: %w", err)
	}

	exts, _ := mime.ExtensionsByType(mimeType)
	ext := ".jpg"
	if len(exts) > 0 {
		ext = exts[0]
	}
	tmpImg, err := os.CreateTemp("", "cover-*"+ext)
	if err != nil {
		return fmt.Errorf("temp cover: %w", err)
	}
	defer os.Remove(tmpImg.Name())
	if _, err := tmpImg.Write(data); err != nil {
		tmpImg.Close()
		return fmt.Errorf("write cover: %w", err)
	}
	_ = tmpImg.Close()

	// Remove existing pictures, then import.
	_ = exec.Command("metaflac", "--remove", "--block-type=PICTURE", flacPath).Run()
	if err := exec.Command("metaflac", "--import-picture-from="+tmpImg.Name(), flacPath).Run(); err != nil {
		return fmt.Errorf("metaflac import failed: %w", err)
	}
	return nil
}

type Song struct {
	SongID      int    `json:"song_id"`
	Title       string `json:"title"`
	Duration    string `json:"duration"`
	TrackNumber int    `json:"track_number"`
	FileName    string `json:"file_name"`
	Data        []byte `json:"-"`
}
type User struct {
	ID          int    `json:"id" db:"uid"`
	Username    string `json:"username" db:"username"`
	Password    string `json:"password_hash" db:"password_hash"`
	ServerIP    string `json:"server_ip" db:"server_ip"`
	CreatedAt   string `json:"created_at" db:"created_at"`
	UpdatedAt   string `json:"updated_at" db:"updated_at"`
	IsAdmin     bool   `json:"isAdmin" db:"is_admin"`
	FirstName   string `json:"first_name" db:"first_name"`
	LastName    string `json:"last_name" db:"last_name"`
	Email       string `json:"email" db:"email"`
	LibraryPath string `json:"library_path" db:"library_path"`
}
type ApplyMetadataRequest struct {
	Title           string `json:"title"`
	Artist          string `json:"artist"`
	AlbumGenre      string `json:"album_genre"`
	AlbumSubgenres  string `json:"album_subgenres"`
	AlbumDate       int    `json:"album_date"`
	AlbumComment    string `json:"album_comment"`
	AlbumCopyright  string `json:"album_copyright"`
	DiscogsID       int    `json:"discogs_id"`
	UseDiscogsNotes bool   `json:"use_discogs_notes"`
}

var (
	db *sql.DB
)

func GetSongsByAlbumID(albumID int) ([]Song, error) {
	rows, err := db.Query(`
		SELECT s.song_id, s.title, um.file_path, s.duration
		FROM songs s
		JOIN user_music um ON s.song_id = um.song_id
		WHERE s.album_id = $1
	`, albumID)
	if err != nil {
		return nil, fmt.Errorf("query songs: %w", err)
	}
	defer rows.Close()

	songs := []Song{}
	for rows.Next() {
		var s Song
		if err := rows.Scan(&s.SongID, &s.Title, &s.FileName, &s.Duration); err != nil {
			return nil, fmt.Errorf("scan song: %w", err)
		}
		songs = append(songs, s)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return songs, nil
}
func GetOrCreateArtist(artistName string) (int, error) {
	var artistID int
	err := db.QueryRow(`
		INSERT INTO artists(name) VALUES($1)
		ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name
		RETURNING artist_id
	`, artistName).Scan(&artistID)
	return artistID, err
}
func NormalizeGenre(raw string) (string, []string) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "Unknown", nil
	}

	parts := strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == ';' || r == '/' || r == '&'
	})

	if len(parts) == 0 {
		return "Unknown", nil
	}

	main := strings.TrimSpace(parts[0])
	sub := []string{}
	for _, p := range parts[1:] {
		p = strings.TrimSpace(p)
		if p != "" && p != main {
			sub = append(sub, p)
		}
	}

	return main, sub
}

func GetOrCreateAlbum(name string, artistID int, year string, cover string, genre string, subgenres string, comment string, copyright string) (int, error) {
	var albumID int
	err := db.QueryRow(`
        INSERT INTO albums(name, artist_id, year, cover_base64, genre, subgenres, comment, copyright)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8)
        ON CONFLICT(name, artist_id) DO UPDATE 
            SET year=EXCLUDED.year,
                cover_base64=EXCLUDED.cover_base64,
                genre=EXCLUDED.genre,
                subgenres=EXCLUDED.subgenres,
                comment=EXCLUDED.comment,
                copyright=EXCLUDED.copyright
        RETURNING album_id
    `, name, artistID, year, cover, genre, subgenres, comment, copyright).Scan(&albumID)
	return albumID, err
}
func UpdateSongMetadata(c *gin.Context) {
	fmt.Println("---- HANDLER REACHED ----")
	songIDParam := c.Param("song_id")

	var req MetadataUpdateRequest
	if err := c.BindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid JSON"})
		return
	}

	var songID int
	fmt.Sscanf(songIDParam, "%d", &songID)

	var remotePath string
	err := db.QueryRow(`SELECT file_path FROM user_music WHERE song_id=$1`, songID).Scan(&remotePath)
	if err != nil {
		c.JSON(500, gin.H{"error": "Song not found"})
		return
	}

	currentUser, err := sftpTools.GetCurrentUser(c)
	if err != nil {
		c.JSON(401, gin.H{"error": "unauthorized"})
		return
	}

	tempDir := filepath.Join(os.TempDir(), "musicapp_metadata")
	_ = os.MkdirAll(tempDir, 0755)
	localTemp := filepath.Join(tempDir, fmt.Sprintf("u%d_%d_edit%s", currentUser.ID, songID, path.Ext(remotePath)))

	err = sftpTools.DownloadFromSFTP(currentUser.ID, remotePath, localTemp)
	if err != nil {
		fmt.Printf("[tagedit] download failed user=%d remote=%s err=%v\n", currentUser.ID, remotePath, err)
		c.JSON(500, gin.H{"error": "Download failed", "details": err.Error()})
		return
	}

	info, err := os.Stat(localTemp)
	if err != nil || info.Size() == 0 {
		fmt.Printf("[tagedit] temp file invalid path=%s err=%v size=%d\n", localTemp, err, info.Size())
		c.JSON(500, gin.H{"error": "Local file missing or empty"})
		return
	}

	tagFile, err := taglib.Read(localTemp)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to open file for metadata"})
		return
	}
	defer tagFile.Close()

	if strings.TrimSpace(req.Title) != "" {
		tagFile.SetTitle(req.Title)
	}
	if strings.TrimSpace(req.Artist) != "" {
		tagFile.SetArtist(req.Artist)
	}
	if strings.TrimSpace(req.Album) != "" {
		tagFile.SetAlbum(req.Album)
	}
	if req.Year != 0 {
		tagFile.SetYear(req.Year)
	}
	if strings.TrimSpace(req.Comment) != "" {
		tagFile.SetComment(req.Comment)
	}
	if strings.TrimSpace(req.Genre) != "" {
		tagFile.SetGenre(req.Genre)
	}

	if err := tagFile.Save(); err != nil {
		c.JSON(500, gin.H{"error": "Failed to save metadata"})
		return
	}

	// If we have a cover and this is a FLAC, embed it into the file using metaflac.
	if strings.TrimSpace(req.CoverBase64) != "" && strings.EqualFold(filepath.Ext(localTemp), ".flac") {
		if err := embedCoverInFlac(localTemp, req.CoverBase64); err != nil {
			fmt.Println("cover embed failed:", err)
		}
	}

	err = sftpTools.UploadAtomic(currentUser.ID, localTemp, remotePath)
	if err != nil {
		c.JSON(500, gin.H{"error": "Upload failed"})
		return
	}

	var albumID int
	err = db.QueryRow(`SELECT album_id FROM songs WHERE song_id=$1`, songID).Scan(&albumID)
	if err != nil {
		fmt.Printf("[tagedit] song_id=%d lookup album_id failed: %v\n", songID, err)
		c.JSON(500, gin.H{"error": "Failed to get album", "details": err.Error()})
		return
	}

	var artistID int
	if strings.TrimSpace(req.Artist) != "" {
		artistID, err = GetOrCreateArtist(req.Artist)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to get or create artist"})
			return
		}
	} else {
		err = db.QueryRow(`SELECT artist_id FROM albums WHERE album_id=$1`, albumID).Scan(&artistID)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to fetch existing artist"})
			return
		}
	}

	var existing struct {
		Name      string
		Genre     string
		Subgenres string
		Year      sql.NullInt64
		Comment   string
		CoverBase string
		Copyright string
	}

	err = db.QueryRow(`
        SELECT name, genre, subgenres, year, comment, cover_base64, copyright
        FROM albums
        WHERE album_id = $1
    `, albumID).Scan(
		&existing.Name,
		&existing.Genre,
		&existing.Subgenres,
		&existing.Year,
		&existing.Comment,
		&existing.CoverBase,
		&existing.Copyright,
	)
	if err == sql.ErrNoRows {
		// Album record missing; fall back to defaults instead of failing.
		fmt.Printf("[tagedit] album_id=%d not found; defaulting album fields\n", albumID)
		existing.Genre = "Unknown"
		existing.Subgenres = ""
		existing.Comment = ""
		existing.CoverBase = ""
		existing.Copyright = ""
	} else if err != nil {
		fmt.Printf("[tagedit] album_id=%d load failed: %v\n", albumID, err)
		c.JSON(500, gin.H{"error": "Failed to load existing album", "details": err.Error()})
		return
	} else {
		fmt.Printf("[tagedit] album_id=%d loaded album row: genre=%q subgenres=%q cover len=%d\n",
			albumID, existing.Genre, existing.Subgenres, len(existing.CoverBase))
	}

	nameToStore := existing.Name
	if strings.TrimSpace(req.Album) != "" {
		nameToStore = req.Album
	}

	var genreToStore string
	var subToStore string
	if strings.TrimSpace(req.Genre) != "" {
		mainGenre, subGenres := NormalizeGenre(req.Genre)
		genreToStore = mainGenre
		subToStore = strings.Join(subGenres, ",")
	} else {
		genreToStore = existing.Genre
		subToStore = existing.Subgenres
	}

	yearToStore := 0
	if existing.Year.Valid {
		yearToStore = int(existing.Year.Int64)
	}
	if req.Year != 0 {
		yearToStore = req.Year
	}

	commentToStore := existing.Comment
	if strings.TrimSpace(req.Comment) != "" {
		commentToStore = req.Comment
	}

	coverToStore := existing.CoverBase
	if strings.TrimSpace(req.CoverBase64) != "" {
		coverToStore = req.CoverBase64
	} else if strings.TrimSpace(req.CoverURL) != "" {
		if b64, err := FetchImageAsBase64(req.CoverURL); err == nil {
			coverToStore = b64
		} else {
			fmt.Println("FetchImageAsBase64 error:", err)
		}
	}

	copyrightToStore := existing.Copyright
	if strings.TrimSpace(req.Copyright) != "" {
		copyrightToStore = req.Copyright
	}

	if albumID == 0 {
		// Create album if it didn't exist.
		newID, err := GetOrCreateAlbum(nameToStore, artistID, fmt.Sprint(yearToStore), coverToStore, genreToStore, subToStore, commentToStore, copyrightToStore)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to create album", "details": err.Error()})
			return
		}
		albumID = newID
	} else {
		_, err = db.Exec(`
        UPDATE albums
        SET name = $1,
            artist_id = $2,
            genre = $3,
            subgenres = $4,
            year = $5,
            comment = $6,
            cover_base64 = $7,
            copyright = $8
        WHERE album_id = $9
    `, nameToStore, artistID, genreToStore, subToStore, yearToStore, commentToStore, coverToStore, copyrightToStore, albumID)

		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to update album", "details": err.Error()})
			return
		}
	}

	_, err = db.Exec(`
        UPDATE user_music
        SET modified_at = NOW()
        WHERE song_id = $1
    `, songID)
	if err != nil {
		fmt.Println("DB UPDATE MODIFIED DATE ERROR:", err)
	}

	c.JSON(200, gin.H{"success": true})
}
