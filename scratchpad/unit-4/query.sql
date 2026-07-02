create or replace procedure print_date is
   v_date varchar2(30);
begin
   select to_char(
      sysdate,
      'Mon DD, YYYY'
   )
     into v_date
     from dual;
   dbms_output.put_line(v_date);
end;

declare
   v_count number(
      6,
      0
   );
begin
   select count(*)
     into v_count
     from employees;
   dbms_output.put_line(v_count || ' employees');
end;

declare
   v_count CONSTANT pls_integer default 0;
begin
   dbms_output.put_line('Counter: '||v_count);
end;