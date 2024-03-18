alter table "public"."logbook" alter column "end" drop not null;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.client_tasks()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  ret jsonb;
BEGIN
  SELECT json_agg(tasks) 
  INTO ret
  FROM (
    SELECT
      t.id,
      b.text as title,
      b.checkbox,
      jsonb_logbook(t.title_block_id) as logbook,
      ta.seconds as allotment,
      (SELECT jsonb_agg(infos) FROM (
        SELECT info.id, info.indent, ib.text, ib.checkbox, 
        jsonb_logbook(info.block_id) as logbook
        FROM info
        JOIN block ib on ib.id = info.block_id
        WHERE info.task_id = t.id
        ORDER BY info.id
      ) infos) as info
    FROM task t
    JOIN time_allotment ta on ta.id = t.allotment_id
    JOIN block b on t.title_block_id = b.id
    WHERE auth.uid() = t.user_id
    GROUP BY t.id, ta.seconds, b.text, b.checkbox
    ORDER BY t.id
    ) tasks;

  return ret;
END
$function$
;

CREATE OR REPLACE FUNCTION public.jsonb_logbook(block_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  ret jsonb;
BEGIN
  SELECT jsonb_agg(lb)
  INTO ret
  FROM (
    SELECT "start", "end" FROM logbook 
    WHERE logbook.block_id = jsonb_logbook.block_id
    ORDER BY logbook.block_id) lb;
  
  return ret;
END
$function$
;


