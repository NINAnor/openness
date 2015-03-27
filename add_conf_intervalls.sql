ALTER TABLE openness.nv_prox_forest_500 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_fjord_1000 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_fjord_100 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_park_500 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_large_park ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_graveyard_500 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_freshwater_200 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;
ALTER TABLE openness.nv_pc_green_500 ADD COLUMN marginal_effect_nok_2_5_perc_conf double precision;

ALTER TABLE openness.nv_prox_forest_500 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_fjord_1000 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_fjord_100 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_park_500 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_large_park ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_graveyard_500 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_prox_freshwater_200 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;
ALTER TABLE openness.nv_pc_green_500 ADD COLUMN marginal_effect_nok_97_5_perc_conf double precision;

UPDATE openness.nv_prox_forest_500 SET marginal_effect_nok_2_5_perc_conf = (500 - distance) *  99.57385738;
UPDATE openness.nv_prox_fjord_1000 SET marginal_effect_nok_2_5_perc_conf = (1000 - distance) *  354.2597068;
UPDATE openness.nv_prox_fjord_100 SET marginal_effect_nok_2_5_perc_conf = 53346.8396;
UPDATE openness.nv_prox_park_500 SET marginal_effect_nok_2_5_perc_conf = (500 - distance) * 161.6039591;
UPDATE openness.nv_large_park SET marginal_effect_nok_2_5_perc_conf = CASE WHEN marginal_effect_nok > 0 THEN 9755.591198 ELSE 0 END;
UPDATE openness.nv_prox_graveyard_500 SET marginal_effect_nok_2_5_perc_conf = (500 - distance) * 209.3379806;
UPDATE openness.nv_prox_freshwater_200 SET marginal_effect_nok_2_5_perc_conf = 50328.25118;
UPDATE openness.nv_pc_green_500 SET marginal_effect_nok_2_5_perc_conf = pc_green * -13867.86762;

UPDATE openness.nv_prox_forest_500 SET marginal_effect_nok_97_5_perc_conf = (500 - distance) *  484.2814884;
UPDATE openness.nv_prox_fjord_1000 SET marginal_effect_nok_97_5_perc_conf = (1000 - distance) *  529.3478721;
UPDATE openness.nv_prox_fjord_100 SET marginal_effect_nok_97_5_perc_conf = 808229.9498;
UPDATE openness.nv_prox_park_500 SET marginal_effect_nok_97_5_perc_conf = (500 - distance) * 367.5556524;
UPDATE openness.nv_large_park SET marginal_effect_nok_97_5_perc_conf = CASE WHEN marginal_effect_nok > 0 THEN 73966.52631 ELSE 0 END;
UPDATE openness.nv_prox_graveyard_500 SET marginal_effect_nok_97_5_perc_conf = (500 - distance) * 503.9844467;
UPDATE openness.nv_prox_freshwater_200 SET marginal_effect_nok_97_5_perc_conf = 124205.6474;
UPDATE openness.nv_pc_green_500 SET marginal_effect_nok_97_5_perc_conf = pc_green * -9964.838323;

SELECT bg_variable, sum(marginal_effect_nok) / 1000000 AS marginal_effect_sum_mio_nok, sum(marginal_effect_nok_2_5_perc_conf) / 1000000 AS marginal_effect_sum_mio_nok_2_5_perc_conf, sum(marginal_effect_nok_97_5_perc_conf) / 1000000 AS marginal_effect_sum_mio_nok_97_5_perc_conf, count(xa.id) AS number_appartments FROM
(
SELECT * FROM openness.nv_prox_forest_500 UNION ALL
SELECT * FROM openness.nv_prox_fjord_1000 UNION ALL
SELECT * FROM openness.nv_prox_fjord_100 UNION ALL
SELECT * FROM openness.nv_prox_park_500 UNION ALL
SELECT * FROM openness.nv_large_park WHERE marginal_effect_nok > 0 UNION ALL
SELECT * FROM openness.nv_prox_graveyard_500 UNION ALL
SELECT * FROM openness.nv_prox_freshwater_200 UNION ALL
SELECT * FROM openness.nv_pc_green_500
) AS xa
GROUP BY bg_variable
ORDER BY marginal_effect_sum_mio_nok;



/* 

b1.prox_marka_500	290.6285003	99.57385738	484.2814884
b2.prox_fjord_1000	441.2407834	354.2597068	529.3478721
b3.area_fjord_100	410552.8747	53346.8396	808229.9498
b4. prox_park_500	263.900191	161.6039591	367.5556524
b5. l_park	41502.11422	9755.591198	73966.52631
b6. prox_graveyard_500	355.6575779	209.3379806	503.9844467
b7. fresh_200	86836.41765	50328.25118	124205.6474
			
s1. prox_cc_9000	103.0376456	90.52426418	115.6803103
s2. pc_500_gre	-11930.8535	-13867.86762	-9964.838323
s3. akers_elva	-149436.5695	-209510.5103	-87378.4293
s4. noise_65_80	-109115.8914	-136596.8335	-81007.16814

--prox_forest_500
(500 - distance) *  290.63 AS marginal_effect_nok
--prox_fjord_1000
(1000 - distance) *  441.24 AS marginal_effect_nok
--prox_fjord_100
410552.87 AS marginal_effect_nok
--prox_park_500
(500 - distance) * 263.90 AS marginal_effect_nok
--large_park
CASE WHEN ST_Area(b.geom) > 100000 THEN 41502.11 ELSE 0 END AS marginal_effect_nok
--prox_graveyard_500
(500 - distance) * 355.66 AS marginal_effect_nok
--freshwater_200
86836.42 AS marginal_effect_nok
--pc_green_500
pc_green * -11930.85 AS marginal_effect_nok
 */
