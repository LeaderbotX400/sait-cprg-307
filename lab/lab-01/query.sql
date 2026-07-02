-- List MM_MEMBER

select *
  from mm_member;

-- Add a new member, update the credit card number for that member, and then delete that member.
insert into mm_member (
   member_id,
   last,
   first
) values ( 15,
           'Smith',
           'John' );

update mm_member
   set
   credit_card = '441120453336'
 where member_id = 15;

delete from mm_member
 where member_id = 15;

-- Display the title of each movie, the rental ID, and the last names of all members who have rented those movies.

select m.movie_title,
       r.rental_id,
       mm.last
  from mm_member mm
  join mm_rental r
on mm.member_id = r.member_id
  join mm_movie m
on r.movie_id = m.movie_id
 order by r.rental_id;

select m.movie_title,
       r.rental_id,
       mm.last
  from mm_member mm,
       mm_rental r,
       mm_movie m
 where mm.member_id = r.member_id
   and r.movie_id = m.movie_id;

-- Custom table and sequence

create table my_table (
   my_number number,
   my_date   date,
   my_string varchar2(5)
);

create sequence my_seq start with 20 increment by 2 nomaxvalue nocycle;

select last_number,
       increment_by
  from user_sequences us
 where sequence_name = 'MY_SEQ';

select my_seq.nextval
  from dual;

alter sequence my_seq increment by 5;

select my_seq.nextval
  from dual;

insert into mm_movie (
   movie_id,
   movie_title,
   mm_movie.movie_cat_id
) values ( my_seq.nextval,
           'The Matrix',
           1 );


create view vw_movie_rental as
   select m.movie_title,
          r.rental_id,
          mm.last
     from mm_member mm
     join mm_rental r
   on mm.member_id = r.member_id
     join mm_movie m
   on r.movie_id = m.movie_id
    order by r.rental_id;

select * from vw_movie_rental;