BEGIN;

TRUNCATE TABLE public.mock_data;

COPY public.mock_data FROM '/data/MOCK_DATA.csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (1).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (2).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (3).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (4).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (5).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (6).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (7).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (8).csv'
WITH (FORMAT csv, HEADER true);

COPY public.mock_data FROM '/data/MOCK_DATA (9).csv'
WITH (FORMAT csv, HEADER true);

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM public.mock_data) <> 10000 THEN
        RAISE EXCEPTION 'Недостаточно строк';
    END IF;
END;
$$;

COMMIT;

SELECT COUNT(*) AS total_rows
FROM public.mock_data;