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
            -- raise notice 'Analyze table %', table_name_var;
            RAISE NOTICE 'Checking size for table %', table_name_var;
            IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = schema_name AND table_name = table_name_var) THEN
                RAISE WARNING 'Table % not found', table_name_var;
                CONTINUE;
            END IF;
            INSERT INTO gp_table_sizes VALUES(schema_name, table_name_var, pg_total_relation_size(quote_ident(schema_name) || '.' || quote_ident(table_name_var)), now());
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION to get size of table

CREATE OR REPLACE FUNCTION analyze_table_size(schema_name text,table_name text) RETURNS void AS $$
DECLARE
    size bigint;
    last_analyzed_var timestamp;
BEGIN
    INSERT INTO gp_table_sizes VALUES(schema_name,table_name, pg_total_relation_size(quote_ident(schema_name) || '.' || quote_ident(table_name)), now());
END;
$$ LANGUAGE plpgsql;
