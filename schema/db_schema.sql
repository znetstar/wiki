drop table if exists wiki_meta cascade;
drop table if exists wiki_users cascade;
drop table if exists wiki_sessions cascade;

create table wiki_meta (
	id serial primary key,
	name varchar(255) unique not null,
	value text not null
);

create table wiki_users (
	id serial primary key,
	fname varchar(255) not null,
	lname varchar(255) not null,
	email varchar(255) unique not null,
	password char(60)
);

create table wiki_sessions(
	id serial primary key,
	user_id serial references wiki_users(id),
	created timestamp not null,
	token uuid not null
);

insert into wiki_meta(name,value) values('title', 'Wiki');
insert into wiki_meta(name,value) values('logo', '/img/book.svg');