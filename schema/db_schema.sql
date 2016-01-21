drop table if exists wiki_meta cascade;
drop table if exists wiki_users cascade;
drop table if exists wiki_sessions cascade;
drop table if exists wiki_history cascade;
drop table if exists wiki_bookmarks cascade;

drop table if exists wiki_articles cascade;
drop table if exists wiki_article_tags cascade;
drop table if exists wiki_article_comments cascade;
drop table if exists wiki_article_revisions cascade;


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

create table wiki_articles(
	id serial primary key,
	title varchar(255),
	created timestamp not null default current_timestamp,
	modified timestamp,
	hits bigint not null default 0
);

create table wiki_article_tags(
	id serial primary key,
	tag text not null,
	article_id serial references wiki_articles(id),
	user_id serial references wiki_users(id),
	constraint unique_tag unique (tag,article_id,user_id)
);

create table wiki_article_comments(
	id serial primary key,
	tag text not null,
	article_id serial references wiki_articles(id),
	user_id serial references wiki_users(id),
	created timestamp not null default current_timestamp,
	flagged boolean not null default false
);

create table wiki_article_revisions(
	id serial primary key,
	article_id serial references wiki_articles(id),
	user_id serial references wiki_users(id),
	created timestamp not null default current_timestamp,
	body text not null default ''
);

create table wiki_history(
	id serial primary key,
	user_id serial references wiki_users(id),
	article_id serial references wiki_articles(id),
	viewed timestamp not null
);

create table wiki_bookmarks(
		id serial primary key,
		user_id serial references wiki_users(id),
		article_id serial references wiki_articles(id),
		last_viewed timestamp not null,
		first_viewed timestamp not null
	);

insert into wiki_meta(name,value) values('title', 'Wiki');
insert into wiki_meta(name,value) values('logo', '/img/book.svg');