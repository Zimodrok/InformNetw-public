--
-- PostgreSQL database dump
--

\restrict 4xGUX3unkqDzdE2DKeSqfqC8ubNhpepieEIGVWT5GUW3BeAN5SHU0uN84SJQFyb

-- Dumped from database version 17.6 (Homebrew)
-- Dumped by pg_dump version 17.6 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: musicuser
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO musicuser;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_logs; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.access_logs (
    id integer NOT NULL,
    user_id integer,
    song_id integer,
    accessed_at timestamp without time zone DEFAULT now(),
    ip_addr character varying(50)
);


ALTER TABLE public.access_logs OWNER TO musicuser;

--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.access_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_logs_id_seq OWNER TO musicuser;

--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.access_logs_id_seq OWNED BY public.access_logs.id;


--
-- Name: albums; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.albums (
    album_id integer NOT NULL,
    name character varying(255) NOT NULL,
    artist_id integer,
    year text,
    cover_base64 text,
    genre character varying(100) DEFAULT 'Unknown'::character varying,
    copyright character varying(255),
    comment text,
    subgenres text
);


ALTER TABLE public.albums OWNER TO musicuser;

--
-- Name: albums_album_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.albums_album_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albums_album_id_seq OWNER TO musicuser;

--
-- Name: albums_album_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.albums_album_id_seq OWNED BY public.albums.album_id;


--
-- Name: artists; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.artists (
    artist_id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.artists OWNER TO musicuser;

--
-- Name: artists_artist_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.artists_artist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.artists_artist_id_seq OWNER TO musicuser;

--
-- Name: artists_artist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.artists_artist_id_seq OWNED BY public.artists.artist_id;


--
-- Name: sftp_file_hash; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.sftp_file_hash (
    id integer NOT NULL,
    user_id integer NOT NULL,
    song_id integer NOT NULL,
    file_path text NOT NULL,
    size bigint NOT NULL,
    sha256 text NOT NULL,
    last_verified timestamp with time zone DEFAULT now()
);


ALTER TABLE public.sftp_file_hash OWNER TO musicuser;

--
-- Name: sftp_file_hash_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.sftp_file_hash_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sftp_file_hash_id_seq OWNER TO musicuser;

--
-- Name: sftp_file_hash_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.sftp_file_hash_id_seq OWNED BY public.sftp_file_hash.id;


--
-- Name: songs; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.songs (
    song_id integer NOT NULL,
    title character varying(255) NOT NULL,
    album_id integer,
    duration text,
    track_number integer,
    uid uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public.songs OWNER TO musicuser;

--
-- Name: songs_song_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.songs_song_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.songs_song_id_seq OWNER TO musicuser;

--
-- Name: songs_song_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.songs_song_id_seq OWNED BY public.songs.song_id;


--
-- Name: upload_tasks; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.upload_tasks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    song_id integer NOT NULL,
    album_id integer NOT NULL,
    temp_path text NOT NULL,
    target_path text NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.upload_tasks OWNER TO musicuser;

--
-- Name: upload_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.upload_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.upload_tasks_id_seq OWNER TO musicuser;

--
-- Name: upload_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.upload_tasks_id_seq OWNED BY public.upload_tasks.id;


--
-- Name: user_music; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.user_music (
    id integer NOT NULL,
    user_id integer,
    song_id integer,
    file_path text NOT NULL,
    uploaded_at timestamp without time zone DEFAULT now(),
    modified_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_music OWNER TO musicuser;

--
-- Name: user_music_id_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.user_music_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_music_id_seq OWNER TO musicuser;

--
-- Name: user_music_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.user_music_id_seq OWNED BY public.user_music.id;


--
-- Name: user_sftp; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.user_sftp (
    uid integer NOT NULL,
    server_ip text,
    server_port integer DEFAULT 22,
    sftp_user text,
    sftp_password_enc text,
    library_path text,
    user_id integer,
    os_absolute_path text
);


ALTER TABLE public.user_sftp OWNER TO musicuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: musicuser
--

CREATE TABLE public.users (
    uid integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_admin boolean DEFAULT false,
    first_name text,
    last_name text,
    email text
);


ALTER TABLE public.users OWNER TO musicuser;

--
-- Name: users_uid_seq; Type: SEQUENCE; Schema: public; Owner: musicuser
--

CREATE SEQUENCE public.users_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_uid_seq OWNER TO musicuser;

--
-- Name: users_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: musicuser
--

ALTER SEQUENCE public.users_uid_seq OWNED BY public.users.uid;


--
-- Name: access_logs id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.access_logs ALTER COLUMN id SET DEFAULT nextval('public.access_logs_id_seq'::regclass);


--
-- Name: albums album_id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.albums ALTER COLUMN album_id SET DEFAULT nextval('public.albums_album_id_seq'::regclass);


--
-- Name: artists artist_id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.artists ALTER COLUMN artist_id SET DEFAULT nextval('public.artists_artist_id_seq'::regclass);


--
-- Name: sftp_file_hash id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.sftp_file_hash ALTER COLUMN id SET DEFAULT nextval('public.sftp_file_hash_id_seq'::regclass);


--
-- Name: songs song_id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.songs ALTER COLUMN song_id SET DEFAULT nextval('public.songs_song_id_seq'::regclass);


--
-- Name: upload_tasks id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.upload_tasks ALTER COLUMN id SET DEFAULT nextval('public.upload_tasks_id_seq'::regclass);


--
-- Name: user_music id; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_music ALTER COLUMN id SET DEFAULT nextval('public.user_music_id_seq'::regclass);


--
-- Name: users uid; Type: DEFAULT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.users ALTER COLUMN uid SET DEFAULT nextval('public.users_uid_seq'::regclass);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (album_id);


--
-- Name: albums albums_unique_name_artist; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_unique_name_artist UNIQUE (name, artist_id);


--
-- Name: artists artists_name_key; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_name_key UNIQUE (name);


--
-- Name: artists artists_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY (artist_id);


--
-- Name: sftp_file_hash sftp_file_hash_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.sftp_file_hash
    ADD CONSTRAINT sftp_file_hash_pkey PRIMARY KEY (id);


--
-- Name: songs songs_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (song_id);


--
-- Name: songs songs_unique_title_album; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_unique_title_album UNIQUE (title, album_id);


--
-- Name: users unique_email; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- Name: upload_tasks upload_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.upload_tasks
    ADD CONSTRAINT upload_tasks_pkey PRIMARY KEY (id);


--
-- Name: user_music user_music_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_music
    ADD CONSTRAINT user_music_pkey PRIMARY KEY (id);


--
-- Name: user_music user_music_user_id_song_id_key; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_music
    ADD CONSTRAINT user_music_user_id_song_id_key UNIQUE (user_id, song_id);


--
-- Name: user_sftp user_sftp_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_sftp
    ADD CONSTRAINT user_sftp_pkey PRIMARY KEY (uid);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (uid);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_sftp_file_hash_user_song; Type: INDEX; Schema: public; Owner: musicuser
--

CREATE INDEX idx_sftp_file_hash_user_song ON public.sftp_file_hash USING btree (user_id, song_id);


--
-- Name: idx_upload_tasks_status; Type: INDEX; Schema: public; Owner: musicuser
--

CREATE INDEX idx_upload_tasks_status ON public.upload_tasks USING btree (status);


--
-- Name: access_logs access_logs_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_song_id_fkey FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON DELETE CASCADE;


--
-- Name: access_logs access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(uid) ON DELETE CASCADE;


--
-- Name: albums albums_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(artist_id) ON DELETE CASCADE;


--
-- Name: songs songs_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(album_id) ON DELETE CASCADE;


--
-- Name: user_music user_music_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_music
    ADD CONSTRAINT user_music_song_id_fkey FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON DELETE CASCADE;


--
-- Name: user_music user_music_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_music
    ADD CONSTRAINT user_music_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(uid) ON DELETE CASCADE;


--
-- Name: user_sftp user_sftp_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_sftp
    ADD CONSTRAINT user_sftp_uid_fkey FOREIGN KEY (uid) REFERENCES public.users(uid) ON DELETE CASCADE;


--
-- Name: user_sftp user_sftp_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: musicuser
--

ALTER TABLE ONLY public.user_sftp
    ADD CONSTRAINT user_sftp_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(uid) ON DELETE CASCADE;


--
-- Name: user_music; Type: ROW SECURITY; Schema: public; Owner: musicuser
--

ALTER TABLE public.user_music ENABLE ROW LEVEL SECURITY;

--
-- Name: user_music user_policy; Type: POLICY; Schema: public; Owner: musicuser
--

CREATE POLICY user_policy ON public.user_music USING ((user_id = (current_setting('app.current_user_id'::text))::integer));


--
-- Name: TABLE user_sftp; Type: ACL; Schema: public; Owner: musicuser
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_sftp TO musicuser;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_sftp TO music_app_user;


--
-- PostgreSQL database dump complete
--

\unrestrict 4xGUX3unkqDzdE2DKeSqfqC8ubNhpepieEIGVWT5GUW3BeAN5SHU0uN84SJQFyb

