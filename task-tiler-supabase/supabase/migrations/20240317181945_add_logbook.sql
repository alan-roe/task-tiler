alter table "public"."logbook" alter column "end" set data type timestamp without time zone using "end"::timestamp without time zone;

alter table "public"."logbook" alter column "start" set data type timestamp without time zone using "start"::timestamp without time zone;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.add_logbook(block_id bigint, log_json jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  startt timestamp;
  endt timestamp;
  ret_id bigint;
BEGIN
  startt := (log_json ->> 'start_time')::timestamp;
  endt := (log_json ->> 'end_time')::timestamp;
  INSERT INTO logbook ("block_id", "start", "end")
  VALUES (block_id, startt, endt) 
  RETURNING id INTO ret_id;
  
  return ret_id;
END
$function$
;

CREATE OR REPLACE FUNCTION public.add_block(block jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  buuid uuid;
  btext text;
  bcheckbox checkbox;
  bid bigint;
  logbook_json jsonb[];
  log jsonb;
BEGIN
  buuid := block ->> 'uuid';
  btext := block ->> 'text';
  bcheckbox := block ->> 'checkbox';
  SELECT array_agg(logs) INTO logbook_json
  FROM jsonb_array_elements(block -> 'logbook') logs;

  INSERT INTO block (uuid, text, checkbox)
  VALUES (buuid, btext, bcheckbox)
  RETURNING id INTO bid;

  IF logbook_json IS NOT NULL THEN
    FOREACH log IN ARRAY logbook_json
    LOOP
      PERFORM add_logbook(bid, log);
    END LOOP;
  END IF;  
  return bid;
END
$function$
;


