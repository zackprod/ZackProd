--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: connextionoperateur(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.connextionoperateur(idop character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$



BEGIN 

return ( select row_to_json(t)  as a 
from (  
    select  idOperateur,Username,shift,cat_piece from Operateur where idOperateur=IDop
   
)t
);
   
END; $$;


--
-- Name: data_shift_reeltime(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.data_shift_reeltime(iduser integer) RETURNS json
    LANGUAGE plpgsql
    AS $$



BEGIN
       
  return ( select array_to_json(array_agg(row_to_json(t)))  
from (  
select id,idshift,datecurent ,get_clock_rate(IdUser,id) from Pieces where DATE(datecurent)=current_date AND current_time between (select timeshiftbegin from shift where idshift=Pieces.idshift) and (select timeshiftend from shift where idshift=Pieces.idshift)  
)t
);
   
END; $$;


--
-- Name: get_clock_rate(character varying, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_clock_rate(iduser character varying, parmshift character) RETURNS interval
    LANGUAGE plpgsql
    AS $$

DECLARE
  a timestamp ;
  b timestamp ;
  idpiece INTEGER;

BEGIN
   
 if IdPiece = (select id from pieces  where shiftp=parmshift AND DATE(timing) = current_date  AND idop=IdUser order by id  limit 1 ) then
    RETURN 10;
  else
    select into idpiece id from pieces  where shiftp=parmshift AND DATE(timing) = current_date AND idop=IdUser  order by id desc limit 1;

    select into a  timing from Pieces where id=IdPiece And  idop=IdUser; 
    select into  b timing from Pieces where id=(select id from Pieces where id<IdPiece order by id  LIMIT 1) And  idop=IdUser AND shiftp=parmshift ;
         if b is null then
		return 10;
         end if;
        return a-b;
         
  END IF ; 
END; $$;


--
-- Name: get_operateur_reeltime(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_operateur_reeltime() RETURNS json
    LANGUAGE plpgsql
    AS $$


begin 
if LOCALTIME > time'22:00:00' and LOCALTIME < time'23:59:59' OR LOCALTIME > time'00:00:00' and LOCALTIME < time'06:00:00' then
return( 

    select array_to_json(array_agg(row_to_json(t))) as a from (select operateur.idoperateur,operateur.username,operateur.email,operateur.shift,cat_piece ,get_tic_time((select id from pieces  where idop=operateur.idoperateur AND shiftp=operateur.shift order by id desc limit 1),operateur.idoperateur,operateur.shift) from operateur,shift where operateur.shift='C' group by idoperateur )t
);
else
return(
    select array_to_json(array_agg(row_to_json(t))) as a from (select operateur.idoperateur,operateur.username,operateur.email,operateur.shift,cat_piece ,get_tic_time((select id from pieces  where idop=operateur.idoperateur AND shiftp=operateur.shift order by id desc limit 1),operateur.idoperateur,operateur.shift) from operateur,shift where operateur.shift=shift.id AND current_time between shift.begintime and shift.endtime  group by idoperateur )t
);


end if;

end; $$;


--
-- Name: get_temp_realiser(character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_temp_realiser(idshift character) RETURNS time without time zone
    LANGUAGE plpgsql
    AS $$

BEGIN 
return(
select   current_time-begintime from shift where id=idshift
);
END;$$;


--
-- Name: get_temp_restant(character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_temp_restant(idshift character) RETURNS time without time zone
    LANGUAGE plpgsql
    AS $$

BEGIN 
return(
select   endtime-localtime from shift where id=idshift
);
END;$$;


--
-- Name: get_tic_time(integer, character varying, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_tic_time(idpiece integer, iduser character varying, parmshift character) RETURNS interval
    LANGUAGE plpgsql
    AS $$

DECLARE
  a timestamp ;
  b timestamp ;

BEGIN
   
 if idpiece = (select id from pieces  where shiftp=parmshift AND DATE(timing) = current_date  AND idop=IdUser order by id  limit 1 ) then
    RETURN 10;
  else

    select into  a  timing from Pieces where id=idpiece And  idop=IdUser ;
    select into b timing  from Pieces where   idop=iduser AND id<idpiece   and shiftp=parmshift  order by timing desc limit 1 ; 
 

         if b is null then
		return 10;
         end if;
        return a-b;
         
  END IF ; 
END; $$;


--
-- Name: getreeltime(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.getreeltime(iduser character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 
 A INTEGER;
 B INTEGER;
 tmpR interval;
 sh char;
 cate varchar;
 tempsecoule double precision	;
  tempsrealise double precision	;
  tictime_objectif double precision;
    tictime double precision;
   temprestant time;
 tmpstandard time;
 begin

 select into sh shift from operateur where idoperateur=iduser;
select into cate cat_piece  from operateur where idoperateur =iduser;
 select count(*) into A    from pieces where idop=iduser and to_date(to_char(timing, 'YYYY/MM/DD'), 'YYYY/MM/DD') = current_date AND status='true' and cat=cate ;
select count(*)  into B    from pieces where idop=iduser and to_date(to_char(timing, 'YYYY/MM/DD'), 'YYYY/MM/DD') = current_date AND status='false' and cat=cate;
select into tmpstandard temp_standard from cat_piece where categorie=cate;
select into tempsrealise EXTRACT(second from tmpstandard*A)+EXTRACT(minute from tmpstandard*A)*60+EXTRACT(hour from tmpstandard*A)*3600;
select into tempsecoule EXTRACT(second from get_temp_realiser(sh))+EXTRACT(minute from get_temp_realiser(sh))*60+EXTRACT(hour from get_temp_realiser(sh))*3600  ;
select into tictime_objectif EXTRACT(second from temp_standard)+EXTRACT(minute from temp_standard)*60+EXTRACT(hour from temp_standard)*3600 from cat_piece where categorie=cate;

  return ( select array_to_json(array_agg(row_to_json(t)))  
from (  
select get_temp_restant(sh)::TIME as temp_restant ,get_temp_realiser(sh) as tmpecouler ,id,timing, ( EXTRACT(second from get_tic_time(id,iduser,shiftp))+EXTRACT(minute from get_tic_time(id,iduser,shiftp))*60+EXTRACT(hour from get_tic_time(id,iduser,shiftp))*3600   ) as tictime ,A as v,B as nv
,(tempsrealise/tempsecoule)*100 as efficience , tempsecoule/A as tictimeReel ,tictime_objectif as tictime_objectif,tempsecoule/tictime_objectif as Objectifinstantane,get_temp_realiser(sh) as tempecoule from pieces where idop=iduser AND shiftp=sh   AND to_date(to_char(timing, 'YYYY/MM/DD'), 'YYYY/MM/DD') = current_date  Order by id desc limit 20
)t
);
 end;$$;


--
-- Name: getstatreeltime(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.getstatreeltime(iduser character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$


declare 
 A INTEGER;
 B INTEGER;
 begin
 select  count(*)  into A  from pieces where idop=iduser and to_date(to_char(timing, 'YYYY/MM/DD'), 'YYYY/MM/DD') = current_date AND status='true';
  select  count(*) into B   from pieces where idop=iduser and to_date(to_char(timing, 'YYYY/MM/DD'), 'YYYY/MM/DD') = current_date AND status='false';


        
  return (  A || B  );



 end;$$;


--
-- Name: to_seconds(interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.to_seconds(intera interval) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
    hs INTEGER;
    ms INTEGER;
    s INTEGER;
BEGIN
    SELECT (EXTRACT( HOUR FROM interA  ) * 60*60) INTO hs; 
    SELECT (EXTRACT (MINUTES FROM interA) * 60) INTO ms;
    SELECT (EXTRACT (SECONDS from interA)) INTO s;
    SELECT (hs + ms + s) INTO s;
    RETURN s;
END;$$;


--
-- Name: to_secondst(time without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.to_secondst(intera time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
    hs INTEGER;
    ms INTEGER;
    s INTEGER;
BEGIN
    SELECT (EXTRACT( HOUR FROM interA  ) * 60*60) INTO hs; 
    SELECT (EXTRACT (MINUTES FROM interA) * 60) INTO ms;
    SELECT (EXTRACT (SECONDS from interA)) INTO s;
    SELECT (hs + ms + s) INTO s;
    RETURN s;
END;$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cat_piece; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public.cat_piece (
    id integer NOT NULL,
    categorie character varying NOT NULL,
    objectif integer,
    temp_standard time without time zone
);


--
-- Name: cat_piece_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cat_piece_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cat_piece_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cat_piece_id_seq OWNED BY public.cat_piece.id;


--
-- Name: operateur; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public.operateur (
    idoperateur character varying NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(355) NOT NULL,
    shift character(1) NOT NULL,
    cat_piece character varying NOT NULL
);


--
-- Name: pieces; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public.pieces (
    id integer NOT NULL,
    idop character varying NOT NULL,
    cat character varying NOT NULL,
    shiftp character(1) NOT NULL,
    timing timestamp without time zone NOT NULL,
    status boolean NOT NULL
);


--
-- Name: pieces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pieces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pieces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pieces_id_seq OWNED BY public.pieces.id;


--
-- Name: projet; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public.projet (
    id integer NOT NULL,
    namepj character varying NOT NULL
);


--
-- Name: projet_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projet_id_seq OWNED BY public.projet.id;


--
-- Name: shift; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public.shift (
    id character(1) NOT NULL,
    begintime time without time zone,
    endtime time without time zone
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cat_piece ALTER COLUMN id SET DEFAULT nextval('public.cat_piece_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces ALTER COLUMN id SET DEFAULT nextval('public.pieces_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projet ALTER COLUMN id SET DEFAULT nextval('public.projet_id_seq'::regclass);


--
-- Data for Name: cat_piece; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cat_piece (id, categorie, objectif, temp_standard) FROM stdin;
1	connecteur	13	00:00:15
\.


--
-- Name: cat_piece_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cat_piece_id_seq', 1, true);


--
-- Data for Name: operateur; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operateur (idoperateur, username, email, shift, cat_piece) FROM stdin;
HH1022	Zakaria El Hedadi	zakaria@gmail.com	C	connecteur
HH1122	El Morsawi Ahmed	AHmed@gmail.com	C	connecteur
\.


--
-- Data for Name: pieces; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pieces (id, idop, cat, shiftp, timing, status) FROM stdin;
864	HH1022	connecteur	C	2019-04-25 22:02:00.91229	t
865	HH1022	connecteur	C	2019-04-25 22:02:02.310027	t
866	HH1022	connecteur	C	2019-04-25 22:02:04.334387	t
867	HH1022	connecteur	C	2019-04-25 22:02:06.549811	t
\.


--
-- Name: pieces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pieces_id_seq', 867, true);


--
-- Data for Name: projet; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projet (id, namepj) FROM stdin;
\.


--
-- Name: projet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.projet_id_seq', 1, false);


--
-- Data for Name: shift; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shift (id, begintime, endtime) FROM stdin;
A	06:00:00	14:00:00
B	14:00:00	22:00:00
C	22:00:00	23:59:59
\.


--
-- Name: cat_piece_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public.cat_piece
    ADD CONSTRAINT cat_piece_pkey PRIMARY KEY (categorie);


--
-- Name: operateur_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public.operateur
    ADD CONSTRAINT operateur_pkey PRIMARY KEY (idoperateur);


--
-- Name: pieces_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public.pieces
    ADD CONSTRAINT pieces_pkey PRIMARY KEY (id);


--
-- Name: projet_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public.projet
    ADD CONSTRAINT projet_pkey PRIMARY KEY (namepj);


--
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public.shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- Name: rf_cat; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operateur
    ADD CONSTRAINT rf_cat FOREIGN KEY (cat_piece) REFERENCES public.cat_piece(categorie);


--
-- Name: rf_shift; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operateur
    ADD CONSTRAINT rf_shift FOREIGN KEY (shift) REFERENCES public.shift(id);


--
-- Name: rfp_catp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces
    ADD CONSTRAINT rfp_catp FOREIGN KEY (cat) REFERENCES public.cat_piece(categorie);


--
-- Name: rfp_operateur; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces
    ADD CONSTRAINT rfp_operateur FOREIGN KEY (idop) REFERENCES public.operateur(idoperateur);


--
-- Name: rfp_shift; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces
    ADD CONSTRAINT rfp_shift FOREIGN KEY (shiftp) REFERENCES public.shift(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

