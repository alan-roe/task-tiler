alter table "public"."info" drop column "order";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.add_info(task_id bigint, info_in jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  indent bigint;
  iid bigint;
BEGIN
  indent := info_in ->> 'indent';
  
  INSERT INTO info (task_id, block_id, indent)
  VALUES (task_id, add_block(info_in -> 'block'), indent)
  RETURNING id INTO iid;

  return iid;
END
$function$
;

CREATE OR REPLACE FUNCTION public.add_logbook(block_id bigint, log_json jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  startt timestamp;
  endt timestamp;
  ret_id bigint;
BEGIN
  startt := (log_json ->> 'start')::timestamp;
  endt := (log_json ->> 'end')::timestamp;
  INSERT INTO logbook ("block_id", "start", "end")
  VALUES (block_id, startt, endt) 
  RETURNING id INTO ret_id;
  
  return ret_id;
END
$function$
;

CREATE OR REPLACE FUNCTION public.add_task(task_json jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  ttitle bigint;
  ttime bigint;
  tid bigint;
  info_arr jsonb[];
  info_json jsonb;
BEGIN
  ttitle := add_block((task_json ->> 'title')::jsonb);
  ttime = add_time_allotment((task_json ->> 'time_allotment')::jsonb);
  SELECT array_agg(infos) INTO info_arr
  FROM jsonb_array_elements(task_json -> 'info') infos;

  INSERT INTO task (user_id, title_block_id, allotment_id)
  VALUES (auth.uid(), ttitle, ttime)
  RETURNING id INTO tid;

  IF info_arr IS NOT NULL THEN
    FOREACH info_json IN ARRAY info_arr
    LOOP
      PERFORM add_info(tid, info_json);
    END LOOP;
  END IF;  

  return tid;
END
$function$
;


