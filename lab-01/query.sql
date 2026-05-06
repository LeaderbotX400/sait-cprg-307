-- List MM_MEMBER

select *
  from mm_member;

-- Add new member
-- begin
insert into mm_member (
   member_id,
   last,
   first
) values ( 15,
           'Smith',
           'John' );

select *
  from mm_member;

update mm_member
   set
   credit_card = '441120453336'
 where member_id = 15;

select *
  from mm_member;
-- Remove membership

delete from mm_member
 where member_id = 15;

select *
  from mm_member;

-- Commit changes

commit;