create table one (
	firstname string not null,
	lastname string not null,
	age integer not null
);

create table two (
	two_id integer not null primary key,
	firstname string not null,
	lastname string not null,
	age integer not null
);

create table three (
	firstname string not null,
	lastname string not null,
	age integer not null,
	primary key ( firstname, lastname )
);

create view four as select * from one;

create view five as select * from two;

create view six as select * from three;
