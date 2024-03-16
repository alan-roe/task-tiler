set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.add_block(block jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
  buuid uuid;
  btext text;
  bcheckbox checkbox;
  bid bigint;
BEGIN
  buuid := block ->> 'uuid';
  btext := block ->> 'text';
  bcheckbox := block ->> 'checkbox';
  INSERT INTO block (uuid, text, checkbox)
  VALUES (buuid, btext, bcheckbox)
  RETURNING id INTO bid;
  
  return bid;
END$function$
;

CREATE OR REPLACE FUNCTION public.add_task(task_json jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
  ttitle bigint;
  ttime bigint;
  tid bigint;
BEGIN
  ttitle := add_block((task_json ->> 'title')::jsonb);
  ttime = add_time_allotment((task_json ->> 'time_allotment')::jsonb);
  -- SELECT * FROM add_block((allotment_json ->> 'block')::jsonb)
  -- INTO bid;
  
  INSERT INTO task (user_id, title_block_id, allotment_id)
  VALUES (auth.uid(), ttitle, ttime)
  RETURNING id INTO tid;

  return tid;
END$function$
;

CREATE OR REPLACE FUNCTION public.add_time_allotment(allotment_json jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
  tseconds bigint;
  bid bigint;
  tid bigint;
BEGIN
  tseconds := allotment_json ->> 'seconds';
  SELECT * FROM add_block((allotment_json ->> 'block')::jsonb)
  INTO bid;
  
  INSERT INTO time_allotment (block_id, seconds)
  VALUES (bid, tseconds)
  RETURNING id INTO tid;

  return tid;
END$function$
;

CREATE OR REPLACE FUNCTION public.get_tasks()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
  ret jsonb;
BEGIN
  SELECT json_agg(t) INTO ret
  FROM (
    SELECT id,
    (SELECT "text" FROM block 
    WHERE block.id = tt.title_block_id) AS title,
    (SELECT seconds FROM time_allotment
    WHERE time_allotment.id = tt.allotment_id) AS time_allotment
    FROM task tt) t;
  return ret;
END$function$
;
