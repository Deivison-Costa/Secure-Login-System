CREATE DATABASE login;

\c login;

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(20),
  password VARCHAR(60),
  login_attempts INTEGER DEFAULT 0
);

