-- Channel video tiers are billed by requested duration, not request count.
ALTER TABLE channel_pricing_intervals
    ADD COLUMN IF NOT EXISTS per_second_price NUMERIC(20, 12);

COMMENT ON COLUMN channel_pricing_intervals.per_second_price
    IS 'Video mode: USD price per generated second for the labelled resolution tier';
