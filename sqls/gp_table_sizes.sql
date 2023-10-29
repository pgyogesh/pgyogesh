-- table for size info


CREATE TABLE IF NOT EXISTS gp_table_sizes (
    schemaname text,
    tbl_name text,
    size bigint,
    last_analyzed timestamp
);

-- Function to get the size information
CREATE OR REPLACE FUNCTION analyze_table_sizes(schema_name text) RETURNS void AS $$
DECLARE
    table_name_var text;
    size bigint;
    last_analyzed_var timestamp;
BEGIN
    FOR table_name_var IN
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = schema_name
        AND table_type = 'BASE TABLE'
    LOOP
        SELECT last_analyzed FROM gp_table_sizes WHERE schemaname = schema_name AND tbl_name = table_name_var INTO last_analyzed_var;
        IF last_analyzed_var IS NULL OR last_analyzed_var < now() - INTERVAL '1 day' THEN
            INSERT INTO gp_table_sizes VALUES(schema_name, table_name_var, pg_total_relation_size(quote_ident(schema_name) || '.' || quote_ident(table_name_var)), now());
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
