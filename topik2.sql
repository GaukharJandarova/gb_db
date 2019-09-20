/* Задача #1.2
   Создайте базу данных example, разместите в ней таблицу users, состоящую из двух столбцов, числового id и строкового name.
*/
--создание БД
DROP DATABASE IF EXISTS example;
CREATE DATABASE example;
USE example;

-- создание таблиц
CREATE TABLE users (
  id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
  name VARCHAR(250) UNIQUE
);