--- Remove default privileges

revoke all privileges on all tables in schema public from public;

--- Backups

create role backups login;

alter default privileges in schema public grant select on sequences to backups;
alter default privileges in schema public grant select on tables to backups;

--- Only needed if already exist at least one database:
--- grant select on all tables in schema public to backups;
--- grant select, usage on all sequences in schema public to backups;
