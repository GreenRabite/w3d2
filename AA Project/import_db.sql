DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

INSERT INTO
  users(fname,lname)
VALUES
  ('Andy','James'),
  ('Bob','Michaels');


DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    u_id INTEGER NOT NULL,

    FOREIGN KEY (u_id) REFERENCES users(id)
);

INSERT INTO
  questions(title,body,u_id)
VALUES
  ('Age','What is your age?',1),
  ('Location','Where are you from?',2);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    q_id INTEGER NOT NULL,
    u_id INTEGER NOT NULL,

    FOREIGN KEY (u_id) REFERENCES users(id),
    FOREIGN KEY (q_id) REFERENCES questions(id)
);

INSERT INTO
  question_follows(q_id,u_id)
VALUES
  (1,1),
  (2,2);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    q_id INTEGER NOT NULL,
    u_id INTEGER NOT NULL,
    parent_id INTEGER,

    FOREIGN KEY (q_id) REFERENCES questions(id),
    FOREIGN KEY (u_id) REFERENCES users(id),
    FOREIGN KEY (parent_id) REFERENCES replies(id)
);

INSERT INTO
  replies(body,q_id,u_id,parent_id)
VALUES
  ('25 years old',1,2, NULL),
  ('Cool man',1,1,1),
  ('Socal',2,1,NULL),
  ('Thats hot mang',2,2,3);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    q_id INTEGER NOT NULL,
    u_id INTEGER NOT NULL,

    FOREIGN KEY (u_id) REFERENCES users(id),
    FOREIGN KEY (q_id) REFERENCES questions(id)
);

INSERT INTO
  question_likes(q_id,u_id)
VALUES
  (1,2);


-- DROP TABLE IF EXISTS plays;
--
-- CREATE TABLE plays (
--   id INTEGER PRIMARY KEY,
--   title TEXT NOT NULL,
--   year INTEGER NOT NULL,
--   playwright_id INTEGER NOT NULL,
--
--   FOREIGN KEY (playwright_id) REFERENCES playwrights(id)
-- );
--
-- DROP TABLE if exists playwrights;
--
-- CREATE TABLE playwrights (
--   id INTEGER PRIMARY KEY,
--   name TEXT NOT NULL,
--   birth_year INTEGER
-- );
--
-- INSERT INTO
--   playwrights (name, birth_year)
-- VALUES
--   ('Arthur Miller', 1915),
--   ('Eugene O''Neill', 1888);
--
-- INSERT INTO
--   plays (title, year, playwright_id)
-- VALUES
--   ('All My Sons', 1947, (SELECT id FROM playwrights WHERE name = 'Arthur Miller')),
--   ('Long Day''s Journey Into Night', 1956, (SELECT id FROM playwrights WHERE name = 'Eugene O''Neill'));
