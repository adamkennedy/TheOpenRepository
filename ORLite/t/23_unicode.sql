create table foo (
    foo_id integer not null primary key,
    name text not null unique,
    text text not null
);

insert into foo values ( 1, 'smiley', '☺');
