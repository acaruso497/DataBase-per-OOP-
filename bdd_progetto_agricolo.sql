---------------TABELLE BASE------------------
CREATE TABLE Proprietario (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome     VARCHAR(50)  NOT NULL,
  cognome  VARCHAR(50)  NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  psw      VARCHAR(100) NOT NULL
  CONSTRAINT chk_valori_distinti
    CHECK (
      nome    <> cognome
      AND nome    <> username
      AND cognome <> username
    )
);

CREATE TABLE Coltivatore (
  Codice_Fiscale VARCHAR(16) PRIMARY KEY,
  nome      VARCHAR(50)  NOT NULL,
  cognome   VARCHAR(50)  NOT NULL,
  username  VARCHAR(100) NOT NULL UNIQUE,
  esperienza VARCHAR(100) NOT NULL DEFAULT 'principiante'
    CHECK (esperienza IN (
      'principiante',
      'intermedio',
      'professionista'
    )),
	psw      VARCHAR(100) NOT NULL,
  CONSTRAINT chk_valori_distinti_coltivatore
    CHECK (
      nome    <> cognome
      AND nome    <> username
      AND cognome <> username
    )
);

CREATE TABLE Progetto_Coltivazione (
  ID_Progetto     INT      PRIMARY KEY,
  titolo       VARCHAR(100) NOT NULL,
  descrizione VARCHAR(200) NOT NULL,
  stima_raccolto   NUMERIC,
  data_inizio      DATE     NOT NULL,
  data_fine        DATE     NOT NULL,
  ID_Lotto         INT  UNIQUE NOT NULL,
  CONSTRAINT chk_intervallo_date
    CHECK (data_fine >= data_inizio)
);

CREATE TABLE Coltura (
  ID_Coltura            INT PRIMARY KEY,
  varietà               VARCHAR(50),
  raccoltoProdotto    	INT DEFAULT 0
);

CREATE TABLE Lotto (
  ID_Lotto       INT        PRIMARY KEY,
  metri_quadri   NUMERIC    NOT NULL
                   CHECK (metri_quadri = 500),
  tipo_terreno   VARCHAR(50),
  posizione      INT        NOT NULL
                   CHECK (posizione BETWEEN 1 AND 200),
  costo_terreno  NUMERIC    NOT NULL
                   CHECK (costo_terreno = 300),
  Codice_FiscalePr VARCHAR(16),
  ID_Progetto        INT  UNIQUE NOT NULL,
  CONSTRAINT uq_posizione UNIQUE (posizione),
  FOREIGN KEY (Codice_FiscalePr) REFERENCES Proprietario(Codice_Fiscale),
  FOREIGN KEY (ID_Progetto) REFERENCES Progetto_Coltivazione(ID_Progetto)
);


CREATE TABLE Attivita (
  ID_Attivita     INT     PRIMARY KEY,
 giorno_assegnazione   DATE NOT NULL DEFAULT CURRENT_DATE,
 CHECK (giorno_assegnazione = CURRENT_DATE),
  Codice_FiscaleCol VARCHAR(16),
  ID_Lotto         INT NOT NULL,
  stato            VARCHAR(50) NOT NULL DEFAULT 'pianificata',
  CONSTRAINT check_stato 
  	CHECK (
  	  stato IN (
	  	'pianificata', 
  	  	'in corso', 
  	  	'completata'
  	)
  ),
  FOREIGN KEY (Codice_FiscaleCol)
    REFERENCES Coltivatore(Codice_Fiscale),
  FOREIGN KEY (ID_Lotto)
    REFERENCES Lotto(ID_Lotto)
);

CREATE TABLE Semina (
  ID_Semina    INT       PRIMARY KEY,
  giorno_inizio   DATE    NOT NULL,
  giorno_fine     DATE    NOT NULL,
	stato            VARCHAR(50) NOT NULL DEFAULT 'pianificata',
  CONSTRAINT check_stato 
  	CHECK (
  	  stato IN (
	  	'pianificata', 
  	  	'in corso', 
  	  	'completata'
  	)
  ),
 CONSTRAINT chk_coerenza_date
    CHECK (giorno_inizio <= giorno_fine),
  
  profondita   NUMERIC   NOT NULL
                CONSTRAINT chk_profondita_std
                  CHECK (profondita = 10),
  tipo_semina  VARCHAR(50),
  ID_Attivita  INT   NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);

CREATE TABLE Irrigazione (
  ID_Irrigazione   INT        PRIMARY KEY,
  giorno_inizio   DATE    NOT NULL,
  giorno_fine     DATE    NOT NULL,
  stato            VARCHAR(50) NOT NULL DEFAULT 'pianificata',
  CONSTRAINT check_stato 
  	CHECK (
  	  stato IN (
	  	'pianificata', 
  	  	'in corso', 
  	  	'completata'
  	)
  ),	
 CONSTRAINT chk_coerenza_date
    CHECK (giorno_inizio <= giorno_fine),
  
  tipo_irrigazione VARCHAR(50) NOT NULL
    CONSTRAINT chk_tipo_irrigazione
      CHECK (
        tipo_irrigazione IN (
          'a goccia',
          'a pioggia',
          'per scorrimento'
        )
      ),
  ID_Attivita      INT        NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);


CREATE TABLE Raccolta (
  ID_Raccolta    INT    PRIMARY KEY,
  giorno_inizio   DATE    NOT NULL,
  giorno_fine     DATE    NOT NULL,
  stato            VARCHAR(50) NOT NULL DEFAULT 'pianificata',
  CONSTRAINT check_stato 
  	CHECK (
  	  stato IN (
	  	'pianificata', 
  	  	'in corso', 
  	  	'completata'
  	)
  ),
   CONSTRAINT chk_coerenza_date
    CHECK (giorno_inizio <= giorno_fine),
  raccolto_effettivo NUMERIC   NOT NULL
                      CONSTRAINT chk_raccolto_non_negativo
                        CHECK (raccolto_effettivo >= 0),
  ID_Attivita        INT  NOT NULL,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);


CREATE TABLE Notifica (
  ID_Notifica          INT PRIMARY KEY,
  Attivita_programmate VARCHAR(200) NOT NULL,
  Data_evento          DATE         NOT NULL,-- !!!forse qua serve un vincolo che la data dell evento non puo essere minore della data attuale !!!!!!
  Utenti_tag           TEXT         NOT NULL,
  Tutti_colt           BOOLEAN      NOT NULL DEFAULT FALSE,
  Titolo               VARCHAR(200) NOT NULL,
  Descrizione       TEXT NOT NULL,
  Lettura           BOOLEAN NOT NULL DEFAULT FALSE,
  ID_Attivita          INT,
  FOREIGN KEY (ID_Attivita) REFERENCES Attivita(ID_Attivita)
);
---------------TABELLE BASE------------------

---------------------FUNZIONE id_Progetto_Coltivazione------------------------------
CREATE OR REPLACE FUNCTION id_Progetto_Coltivazione()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Progetto) INTO ID_var FROM Progetto_Coltivazione;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
     END IF;

   	NEW.ID_Progetto :=ID_var+1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Progetto_Coltivazione------------------------------

---------------------TRIGGER Progetto_Coltivazione------------------------------

CREATE TRIGGER trg_Progetto_Coltivazione_id
BEFORE INSERT ON Progetto_Coltivazione
FOR EACH ROW
EXECUTE FUNCTION id_Progetto_Coltivazione();
---------------------TRIGGER Progetto_Coltivazione------------------------------

---------------------FUNZIONE id_Coltura------------------------------
CREATE OR REPLACE FUNCTION id_Coltura()
RETURNS TRIGGER AS $$ 
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Coltura) INTO ID_var FROM Coltura;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Coltura := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Coltura------------------------------

---------------------TRIGGER Coltura------------------------------
CREATE TRIGGER trg_Coltura_id
BEFORE INSERT ON Coltura
FOR EACH ROW
EXECUTE FUNCTION id_Coltura();
---------------------TRIGGER Coltura------------------------------


---------------------FUNZIONE id_Lotto------------------------------
CREATE OR REPLACE FUNCTION id_Lotto()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Lotto) INTO ID_var FROM Lotto;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Lotto := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Lotto------------------------------

---------------------TRIGGER Lotto------------------------------
CREATE TRIGGER trg_Lotto_id
BEFORE INSERT ON Lotto
FOR EACH ROW
EXECUTE FUNCTION id_Lotto();
---------------------TRIGGER Lotto------------------------------


---------------------FUNZIONE id_Attivita------------------------------
CREATE OR REPLACE FUNCTION id_Attivita()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Attivita) INTO ID_var FROM Attivita;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Attivita := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Attivita------------------------------

---------------------TRIGGER Attivita------------------------------
CREATE TRIGGER trg_Attivita_id
BEFORE INSERT ON Attivita
FOR EACH ROW
EXECUTE FUNCTION id_Attivita();
---------------------TRIGGER Attivita------------------------------


---------------------FUNZIONE id_Semina------------------------------
CREATE OR REPLACE FUNCTION id_Semina()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Semina) INTO ID_var FROM Semina;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Semina := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Semina------------------------------

---------------------TRIGGER Semina------------------------------
CREATE TRIGGER trg_Semina_id
BEFORE INSERT ON Semina
FOR EACH ROW
EXECUTE FUNCTION id_Semina();
---------------------TRIGGER Semina------------------------------


---------------------FUNZIONE id_Irrigazione------------------------------
CREATE OR REPLACE FUNCTION id_Irrigazione()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Irrigazione) INTO ID_var FROM Irrigazione;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Irrigazione := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Irrigazione------------------------------

---------------------TRIGGER Irrigazione------------------------------
CREATE TRIGGER trg_Irrigazione_id
BEFORE INSERT ON Irrigazione
FOR EACH ROW
EXECUTE FUNCTION id_Irrigazione();
---------------------TRIGGER Irrigazione------------------------------


---------------------FUNZIONE id_Raccolta------------------------------
CREATE OR REPLACE FUNCTION id_Raccolta()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Raccolta) INTO ID_var FROM Raccolta;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Raccolta := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Raccolta------------------------------

---------------------TRIGGER Raccolta------------------------------
CREATE TRIGGER trg_Raccolta_id
BEFORE INSERT ON Raccolta
FOR EACH ROW
EXECUTE FUNCTION id_Raccolta();
---------------------TRIGGER Raccolta------------------------------


---------------------FUNZIONE id_Notifica------------------------------
CREATE OR REPLACE FUNCTION id_Notifica()
RETURNS TRIGGER AS $$
DECLARE
    ID_var INTEGER;
    
BEGIN
   SELECT MAX(ID_Notifica) INTO ID_var FROM Notifica;
   
   IF ID_var IS NULL THEN
   	ID_var := 0;
   END IF;

   	NEW.ID_Notifica := ID_var + 1;
   RETURN NEW;

END;

$$ LANGUAGE plpgsql;
---------------------FUNZIONE id_Notifica------------------------------

---------------------TRIGGER Notifica------------------------------
CREATE TRIGGER trg_Notifica_id
BEFORE INSERT ON Notifica
FOR EACH ROW
EXECUTE FUNCTION id_Notifica();
---------------------TRIGGER Notifica------------------------------

-------------FUNZIONE ESPERIENZA DEL COLTIVATORE----------------------

CREATE OR REPLACE FUNCTION trg_promuovi_experience()
  RETURNS trigger AS $$
DECLARE
  cnt     INT;
  old_exp TEXT;
BEGIN
  -- Conta tutte le Attivita del coltivatore (inclusa la nuova)
  SELECT COUNT(*) INTO cnt
    FROM Attivita
   WHERE Codice_FiscaleCol = NEW.Codice_FiscaleCol;

  IF cnt % 5 = 0 THEN
    -- Legge il livello corrente
    SELECT esperienza INTO old_exp
      FROM Coltivatore
     WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;

    -- Promuove al livello successivo a seconda del livello corrente
    IF old_exp = 'principiante' THEN
      UPDATE Coltivatore
         SET esperienza = 'intermedio'
       WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;
    ELSIF old_exp = 'intermedio' THEN
      UPDATE Coltivatore
         SET esperienza = 'professionista'
       WHERE Codice_Fiscale = NEW.Codice_FiscaleCol;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
-------------FUNZIONE ESPERIENZA DEL COLTIVATORE----------------------

-------------TRIGGER ESPERIENZA DEL COLTIVATORE-----------------------
CREATE TRIGGER trg_after_attivita_insert
  AFTER INSERT ON Attivita
  FOR EACH ROW
  EXECUTE FUNCTION trg_promuovi_experience();
-------------TRIGGER ESPERIENZA DEL COLTIVATORE-----------------------


---------------------POPOLAMENTO TABELLE BASE------------------------------

-- Popolamento Proprietario
INSERT INTO Proprietario (Codice_Fiscale, nome, cognome, username, psw) 
VALUES 
  ('SGNMRA88A41F205X', 'Mara',    'Sangiovanni', 'marsan','MaraSNG'),
  ('DMNSRG85T12C351Y', 'Sergio',  'Di Martino',  'serdim','SergioDM');

-- Popolamento Coltivatore (esperienza = default 'principiante')
INSERT INTO Coltivatore (Codice_Fiscale, nome, cognome, username, psw ) 
VALUES
  ('GRCNCL92P10F839Z', 'Nicolo',   'Agricola', 'nicagr','Nico'),
  ('FRLRMN90A01L736X', 'Armando',  'Fiorillo', 'arfior','Arma'),
  ('CRSNTN99C20L378W', 'Antonio',  'Caruso',   'antcar','Anto' );

-- Popolamento Progetto_Coltivazione 
INSERT INTO Progetto_Coltivazione (titolo, descrizione, stima_raccolto, data_inizio, data_fine, ID_Lotto)
VALUES 
  ('Coltivazione zucchine', 'Progetto dedicato alla coltivazione delle zucchine chiare', 1200, '2025-04-01', '2025-07-01', 1),
  ('Coltivazione pomodoro', 'Progetto dedicato alla coltivazione dei pomodori San Marzano', 800, '2025-05-01', '2025-08-01', 2),
  ('Coltivazione pomodoro', 'Progetto dedicato alla coltivazione dei pomodori San Marzano', 800, '2025-05-01', '2025-08-01', 3);

-- Popolamento Lotto
INSERT INTO Lotto (metri_quadri, tipo_terreno, posizione, costo_terreno, Codice_FiscalePr, ID_Progetto) 
VALUES
  (500, 'argilloso', 1, 300, 'SGNMRA88A41F205X', 1),
  (500, 'sabbioso', 2, 300, 'DMNSRG85T12C351Y', 2),
  (500, 'sabbioso', 3, 300, 'DMNSRG85T12C351Y', 3);

-- Popolamento Coltura
INSERT INTO Coltura (varietà)
VALUES
  ('Zucchina Chiara'),
  ('Pomodoro San Marzano');

-- Popolamento Attività
INSERT INTO Attivita (Codice_FiscaleCol, ID_Lotto, stato) 
VALUES
  ('GRCNCL92P10F839Z', 1, 'pianificata'),
  ('FRLRMN90A01L736X', 2, 'pianificata'),
  ('CRSNTN99C20L378W', 1, 'pianificata');
  
-- Popolamento Semina
INSERT INTO Semina (giorno_inizio, giorno_fine, profondita, tipo_semina, ID_Attivita) 
VALUES
  ('2023-01-20', '2023-01-25', 10, 'Diretta', 1),
  ('2023-02-25', '2023-03-02', 10, 'In semenzaio', 2),
  ('2023-03-15', '2023-03-20', 10, 'A spaglio', 3);

-- Popolamento Irrigazione
INSERT INTO Irrigazione (giorno_inizio, giorno_fine, tipo_irrigazione, ID_Attivita) 
VALUES
  ('2023-01-30', '2023-02-05', 'a goccia', 1),
  ('2023-03-10', '2023-03-15', 'a pioggia', 2),
  ('2023-03-25', '2023-03-30', 'per scorrimento', 3);
  
-- Popolamento Raccolta
INSERT INTO Raccolta (giorno_inizio, giorno_fine, raccolto_effettivo, ID_Attivita) 
VALUES
  ('2023-06-10', '2023-06-15', 250.50, 1),
  ('2023-07-05', '2023-07-10', 180.75, 2);

-- Popolamento Notifica
INSERT INTO Notifica
(Attivita_programmate, Data_evento, Utenti_tag, Tutti_colt, Titolo, Descrizione, Lettura, ID_Attivita)
VALUES
  ('Controllare piante', CURRENT_DATE, 'nicagr,arfior', FALSE, 'Verifica piante',  'Controllare lo stato delle piante', FALSE, 1),
  ('Controllare terreno', CURRENT_DATE, 'antcar',         FALSE, 'Verifica terreno','Controllare lo stato del terreno', FALSE, 2);


---------------------POPOLAMENTO TABELLE BASE------------------------------

----------------------TABELLE PONTE-----------------------------------
CREATE TABLE Invia (
  ID_Notifica INT,
  Codice_FiscalePr VARCHAR(16),
  PRIMARY KEY (ID_Notifica, Codice_FiscalePr),
  FOREIGN KEY (ID_Notifica) REFERENCES Notifica(ID_Notifica),
  FOREIGN KEY (Codice_FiscalePr) REFERENCES Proprietario(Codice_Fiscale)
);


CREATE TABLE Progetto_Coltura (
  ID_Progetto INT,
  ID_Coltura  INT,
  PRIMARY KEY (ID_Progetto, ID_Coltura),
  FOREIGN KEY (ID_Progetto) REFERENCES Progetto_Coltivazione(ID_Progetto),
  FOREIGN KEY (ID_Coltura) REFERENCES Coltura(ID_Coltura)
);

----------------------TABELLE PONTE-----------------------------------

---------------------POPOLAMENTO TABELLE PONTE------------------------------

-- Associazione Notifica → Proprietario
INSERT INTO Invia (ID_Notifica, Codice_FiscalePr)
VALUES
  (1, 'SGNMRA88A41F205X'),
  (2, 'DMNSRG85T12C351Y');

-- Associazione Progetto → Coltura
INSERT INTO Progetto_Coltura (ID_Coltura, ID_Progetto)
VALUES
  (1, 1),
  (2, 2),
  (2, 3);
---------------------POPOLAMENTO TABELLE PONTE------------------------------
---------------------VIEW---------------------------------------------------
--_______________________view raccolto______________________________
CREATE OR REPLACE VIEW view_raccolto AS
SELECT
    ra.raccolto_effettivo,
    Prog_c.stima_raccolto,
	Prog_c.data_inizio,
	Prog_c.data_fine,
    prop.Codice_Fiscale
FROM
    Lotto AS L
    JOIN Progetto_Coltivazione AS Prog_c ON l.id_progetto=Prog_c.id_progetto
	JOIN Attivita AS a ON a.id_lotto=L.id_lotto
    JOIN Raccolta AS ra ON ra.id_attivita=a.id_attivita
    JOIN Proprietario AS prop ON prop.Codice_Fiscale=a.Codice_FiscaleCol;

--_______________________view raccolto______________________________


---------------------VIEW---------------------------------------------------
--_______________________view ComboListaColture______________________________
CREATE OR REPLACE VIEW ComboListaColture AS
SELECT 
    pc.id_progetto,
    l.id_lotto,
    col.varietà
FROM Progetto_Coltivazione pc
JOIN Lotto AS l ON l.id_lotto=pc.id_lotto
JOIN Progetto_Coltura pcol ON pc.id_progetto = pcol.id_progetto
JOIN Coltura col ON pcol.id_coltura = col.id_coltura
ORDER BY pc.id_progetto, l.id_lotto, col.varietà;
--_______________________view ComboListaColture______________________________

--_______________________view ComboProgettiColtivatore______________________________
CREATE OR REPLACE VIEW ComboProgettiColtivatore AS
SELECT  
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
GROUP BY c.username, pc.titolo  
ORDER BY pc.titolo;
--_______________________view ComboProgettiColtivatore______________________________

--_______________________view date_progetti_coltivatore______________________________
CREATE OR REPLACE VIEW date_progetti_coltivatore AS
SELECT  
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    pc.data_inizio AS data_inizio_progetto,
    pc.data_fine AS data_fine_progetto
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
ORDER BY pc.titolo;
--_______________________view date_progetti_coltivatore______________________________

--_______________________view DateAttivitaColtivatore______________________________
CREATE OR REPLACE VIEW DateAttivitaColtivatore AS
SELECT  
    att.ID_Attivita,
	l.id_lotto,
	pc.id_progetto,
	s.id_semina,
	i.id_irrigazione,
	r.id_raccolta,
    s.giorno_inizio AS data_inizio_semina,
    s.giorno_fine AS data_fine_semina,
    i.giorno_inizio AS data_inizio_irrigazione,
    i.giorno_fine AS data_fine_irrigazione,
    r.giorno_inizio AS data_inizio_raccolta,
    r.giorno_fine AS data_fine_raccolta
FROM Progetto_Coltivazione AS pc
LEFT JOIN Lotto AS l ON l.id_lotto=pc.id_lotto
LEFT JOIN Attivita att ON att.id_lotto=l.id_lotto
LEFT JOIN Semina s ON att.ID_Attivita = s.ID_Attivita
LEFT JOIN Irrigazione i ON att.ID_Attivita = i.ID_Attivita
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
ORDER BY att.ID_Attivita;
--_______________________view DateAttivitaColtivatore______________________________

--_______________________view AttivitaColtivatore______________________________
CREATE OR REPLACE VIEW AttivitaColtivatore AS
SELECT 
    att.ID_Attivita,
    pc.titolo AS titolo_progetto,
    c.username AS username_coltivatore,
    s.ID_Semina,
    i.ID_Irrigazione,
    r.ID_Raccolta,
    att.giorno_Assegnazione AS data_inizio_attivita
FROM Attivita att
JOIN Coltivatore c ON att.Codice_FiscaleCol = c.Codice_Fiscale
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Semina s ON att.ID_Attivita = s.ID_Attivita
LEFT JOIN Irrigazione i ON att.ID_Attivita = i.ID_Attivita
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
ORDER BY att.giorno_Assegnazione;
--_______________________view AttivitaColtivatore______________________________

--_______________________view ComboAttivitaColtivatore______________________________
CREATE OR REPLACE VIEW ComboAttivitaColtivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    s.ID_Semina AS id_semina,
    i.ID_Irrigazione AS id_irrigazione,
    r.ID_Raccolta AS id_raccolta,
    att.giorno_Assegnazione AS giorno_assegnazione
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Semina s ON att.ID_Attivita = s.ID_Attivita
LEFT JOIN Irrigazione i ON att.ID_Attivita = i.ID_Attivita
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
ORDER BY att.giorno_Assegnazione;
--_______________________view ComboAttivitaColtivatore______________________________

--_______________________view VisualizzaLottoColtivatore______________________________
CREATE OR REPLACE VIEW VisualizzaLottoColtivatore AS
SELECT DISTINCT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    l.ID_Lotto AS id_lotto,
    l.posizione
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
ORDER BY pc.titolo;
--_______________________view VisualizzaLottoColtivatore______________________________

--_______________________view esperienza_coltivatore______________________________
CREATE OR REPLACE VIEW esperienza_coltivatore AS
SELECT 
    username,
    esperienza
FROM Coltivatore
ORDER BY username;
--_______________________view esperienza_coltivatore______________________________

--_______________________view stima_raccoltoColtivatore______________________________
CREATE OR REPLACE VIEW stima_raccoltoColtivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    r.raccolto_effettivo
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
ORDER BY pc.titolo;
--_______________________view stima_raccoltoColtivatore______________________________

--_______________________view tipologia_seminaColtivatore______________________________
CREATE OR REPLACE VIEW tipologia_seminaColtivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    s.tipo_semina
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Semina s ON att.ID_Attivita = s.ID_Attivita
ORDER BY pc.titolo;
--_______________________view tipologia_seminaColtivatore______________________________

--_______________________view ComboTipologiaColturaColtivatore______________________________
CREATE OR REPLACE VIEW ComboTipologiaColturaColtivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    col.varietà AS varieta_coltura
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
JOIN Progetto_Coltura pcol ON pc.ID_Progetto = pcol.id_progetto
JOIN Coltura col ON pcol.id_coltura = col.id_coltura
GROUP BY c.username, pc.titolo, col.varietà  
ORDER BY pc.titolo, col.varietà;
--_______________________view ComboTipologiaColturaColtivatore______________________________

--_______________________view irrigazione_coltivatore______________________________
CREATE OR REPLACE VIEW irrigazione_coltivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    i.tipo_irrigazione
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Irrigazione i ON att.ID_Attivita = i.ID_Attivita
ORDER BY pc.titolo;
--_______________________view irrigazione_coltivatore______________________________

--_______________________view tipo_seminacoltivatore______________________________
CREATE OR REPLACE VIEW semina_view AS
SELECT 
    ID_Semina AS id_semina,
    tipo_semina
FROM Semina
ORDER BY ID_Semina;
--_______________________view tipo_seminacoltivatore______________________________

--_______________________view tipi_attivita_coltivatore______________________________
CREATE OR REPLACE VIEW tipi_attivita_coltivatore AS
SELECT 
    c.username AS username_coltivatore,
    pc.titolo AS titolo_progetto,
    s.ID_Semina AS id_semina,
    i.ID_Irrigazione AS id_irrigazione,
    r.ID_Raccolta AS id_raccolta,
    att.giorno_Assegnazione AS giorno_assegnazione
FROM Coltivatore c
JOIN Attivita att ON c.Codice_Fiscale = att.Codice_FiscaleCol
JOIN Lotto l ON att.ID_Lotto = l.ID_Lotto
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
LEFT JOIN Semina s ON att.ID_Attivita = s.ID_Attivita
LEFT JOIN Irrigazione i ON att.ID_Attivita = i.ID_Attivita
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
ORDER BY att.giorno_Assegnazione;
--_______________________view tipi_attivita_coltivatore______________________________

--_______________________view controllocolture______________________________
CREATE OR REPLACE VIEW controllocolture AS
SELECT 
    l.ID_Lotto AS id_lotto,
    col.varietà
FROM Lotto l
JOIN Progetto_Coltivazione pc ON pc.id_progetto = l.ID_Progetto
JOIN Progetto_Coltura pcol ON pc.ID_Progetto = pcol.id_progetto
JOIN Coltura col ON pcol.id_coltura = col.id_coltura
ORDER BY l.ID_Lotto, col.varietà;
--_______________________view controllocolture______________________________

--_______________________view sommaRaccoltiColtivatore______________________________
CREATE OR REPLACE VIEW sommaRaccolti AS
SELECT 
    pc.ID_Progetto AS id_progetto,
    pc.titolo AS titolo_progetto,
    col.varietà,
    r.ID_Raccolta AS id_raccolta,
    col.raccoltoProdotto
FROM Progetto_Coltivazione pc
JOIN Lotto l ON l.ID_Lotto = pc.ID_Lotto
JOIN Attivita att ON l.ID_Lotto = att.ID_Lotto
LEFT JOIN Raccolta r ON att.ID_Attivita = r.ID_Attivita
JOIN Progetto_Coltura pcol ON pc.ID_Progetto = pcol.id_progetto
JOIN Coltura col ON pcol.id_coltura = col.ID_Coltura
GROUP BY pc.ID_Progetto, pc.titolo, col.varietà, r.ID_Raccolta, col.raccoltoProdotto
ORDER BY pc.ID_Progetto, pc.titolo, col.varietà, r.ID_Raccolta;
--_______________________view sommaRaccoltiColtivatore______________________________

--_______________________view ProprietarioRaccoltoColture______________________________
CREATE OR REPLACE VIEW ProprietarioRaccoltoColture AS
SELECT 
col.raccoltoprodotto,
col.varietà,
pcol.id_coltura,
pc.id_progetto,
l.ID_Lotto
FROM Coltura AS col
LEFT JOIN Progetto_Coltura AS pcol ON col.id_coltura=pcol.id_coltura
LEFT JOIN Progetto_Coltivazione AS pc ON pc.id_progetto=pcol.id_progetto
LEFT JOIN Lotto AS l ON l.ID_Lotto=pc.ID_Lotto
--_______________________view ProprietarioRaccoltoColture______________________________

