-- Function to get bloat of a table

CREATE OR REPLACE FUNCTION get_bloat(tbl_name text)
  RETURNS TABLE(live_tuples bigint, all_tuples bigint, dead_tuples bigint, bloat_ratio float, comment text) AS
$func$
DECLARE
    live_tuples bigint;
    all_tuples bigint;
    dead_tuples bigint;
    bloat_ratio float;
    comment text;
BEGIN
	SET gp_select_invisible = false;
    -- Get the live tuples
    EXECUTE 'SELECT COUNT(*) FROM ' || tbl_name INTO live_tuples;
    -- Set gp_select_invisible = true;
    SET gp_select_invisible = true;
    -- Get the all tuples
    EXECUTE 'SELECT COUNT(*) FROM ' || tbl_name INTO all_tuples;
    SET gp_select_invisible = false;
	-- Get the dead tuples
    dead_tuples := all_tuples - live_tuples;
    -- Get the bloat ratio with exception division by zero
    IF all_tuples = 0 THEN
        bloat_ratio := 0;
    ELSE
        bloat_ratio := dead_tuples::float / all_tuples::float;
    END IF;
    CASE 
        WHEN bloat_ratio > 0.7 THEN
            comment := 'Significantly bloated, VACUUM FULL recommended';
        WHEN bloat_ratio > 0.5 THEN
            comment := 'Moderately bloated, VACUUM recommended';
        WHEN bloat_ratio > 0.2 THEN
            comment := 'Slightly bloated, VACUUM recommended';
        ELSE
            comment := 'Not bloated';
    END CASE; 
    RETURN QUERY SELECT live_tuples, all_tuples, dead_tuples, bloat_ratio, comment;
END
$func$ LANGUAGE plpgsql;

-- Table to store the bloat information
CREATE TABLE IF NOT EXISTS gp_bloat_info (
    tbl_name text,
    live_tuples bigint,
    all_tuples bigint,
    dead_tuples bigint,
    bloat_ratio float,
    comment text,
    last_analyzed timestamp
);

-- Function to get the bloat information
CREATE OR REPLACE FUNCTION analyze_bloat(schema_name text) RETURNS void AS $$
DECLARE
    table_name_var text;
    live_tuples bigint;
    all_tuples bigint;
    dead_tuples bigint;
    bloat_ratio float;
    comment text;
    last_analyzed_var timestamp;
BEGIN
    FOR table_name_var IN
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = schema_name
        AND table_type = 'BASE TABLE'
    LOOP
        SELECT last_analyzed FROM bloat_info WHERE table_name = table_name_var INTO last_analyzed_var;
        IF last_analyzed_var IS NULL OR last_analyzed_var < now() - INTERVAL '1 day' THEN
            SELECT * FROM get_bloat(table_name_var) INTO live_tuples, all_tuples, dead_tuples, bloat_ratio, comment;
            INSERT INTO bloat_info VALUES (table_name_var, live_tuples, all_tuples, dead_tuples, bloat_ratio, comment, now());
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;