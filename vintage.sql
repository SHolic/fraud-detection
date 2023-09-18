--odps sql 
--********************************************************************--
--author:盛浩亮
--create time:2022-08-01 16:39:17
--********************************************************************--

-- 筛选订单
set odps.sql.type.system.odps2=true;
drop table if exists filtered_repayinfo_shl;
create table filtered_repayinfo_shl as
select * from (
select a.* 
, art_name
-- , case when a.order_time<=minlimitrepaytime then 'new' else 'old' end as usertype
, case when a.user_type='new_1' then 'new' else 'old' end as usertype
, case when a.order_code_pre in (10,12,13,20,26,32,34,36,38,60,61,62,63,65,66,67,68,69,17,71,72,75,76,40,41,42,43,44,45,46,64,19) then '商品'
       when a.order_code_pre in (33,39,25,27,51,52,53,54,18) then '借款' else '其他' end as productline
, case when nvl(category_two_name_new, standard_category_2) in ('金银投资','黄金','二手手机通讯') then '高风险套现'
    when nvl(category_two_name_new, standard_category_2) in ('手机', '电脑整机','影音娱乐','智能设备','腕表','流行男鞋','白酒','电脑组件') then '易套现'
    when a.order_code_pre in (33,39,25,27,51,52,53,54,18) then '借款'
    -- when a.order_code_pre=36 then '虚拟正常品类'
    when nvl(category_two_name_new, standard_category_2) is null or nvl(category_two_name_new, standard_category_2) in ('','NULL') then '空值'
    -- else '非虚拟正常品类' end as ctggrade
    else '正常品类' end as ctggrade
, nvl(category_two_name_new, standard_category_2) as ctg
, apr
, irr
-- , a.staging_amo/a.stagin_count as yh_bj
-- , case when f.purchase_amount is null then g.purchase_amount else f.purchase_amount/100 end as cost
, last_day(add_months(a.effect_time,1)) as mob1_time
, last_day(add_months(a.effect_time,2)) as mob2_time
, last_day(add_months(a.effect_time,3)) as mob3_time
, last_day(add_months(a.effect_time,4)) as mob4_time
, last_day(add_months(a.effect_time,5)) as mob5_time
, last_day(add_months(a.effect_time,6)) as mob6_time
, last_day(add_months(a.effect_time,7)) as mob7_time
, last_day(add_months(a.effect_time,8)) as mob8_time
, last_day(add_months(a.effect_time,9)) as mob9_time
, last_day(add_months(a.effect_time,10)) as mob10_time
, last_day(add_months(a.effect_time,11)) as mob11_time
, last_day(add_months(a.effect_time,12)) as mob12_time
from (select * from basestone_dp.bt_order_repay_info where dt=0000) a
left join basestone_dp_dev.bi_order_category_info b
on a.order_code=b.order_code
left join (select * from basestone_dp.bt_order_bas_info where dt=0000) c
on a.order_code=c.order_code
-- left join (
--     select id_num
--     , min(frist_limit_repay_time) as minlimitrepaytime
--     from (select * from bt_order_loan_back_info where dt=0000)
--     group by id_num
-- ) d
-- on a.id_num=d.id_num
-- left join (select * from basestone_dev.bs_om_purchase where dt=0000) f
-- on a.order_code=f.order_code
-- left join (select * from basestone.rs_business_logistics_purchase where dt=0000) g
-- on a.order_code=g.order_code
left join basestone_dp.bt_order_loan_rate_calc h
on a.order_code=h.order_code
where a.effect_time between '2022-01-01' and '2023-01-31'
)
where productline='商品'
;

select count(*) from filtered_repayinfo_shl;


-- 构造观察期内贷余，逾期天数
set odps.sql.type.system.odps2=true;
drop table if exists tmp_repayinfo_shl;
create table tmp_repayinfo_shl as
select order_code
, effect_time
, id_num
, usertype
, ctggrade
, ctg
, staging_amo
-- , limit_interest
-- , cost
, stagin_count
, art_name
, apr
, irr
, mob1_time
, mob2_time
, mob3_time
, mob4_time
, mob5_time
, mob6_time
, mob7_time
, mob8_time
, mob9_time
, mob10_time
, mob11_time
, mob12_time
,case when limit_repay_time <= mob1_time and TO_DATE(mob1_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob1_time,limit_repay_time)
       when limit_repay_time <= mob1_time and TO_DATE(mob1_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob1_time
       then DATEDIFF(mob1_time,limit_repay_time)
       else 0 end as mob1_overday
,case when  limit_repay_time <= mob2_time and TO_DATE(mob2_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob2_time,limit_repay_time)
       when limit_repay_time <= mob2_time and TO_DATE(mob2_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob2_time
       then DATEDIFF(mob2_time,limit_repay_time)
       else 0 end as mob2_overday
,case when  limit_repay_time <= mob3_time and TO_DATE(mob3_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob3_time,limit_repay_time)
       when limit_repay_time <= mob3_time and TO_DATE(mob3_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob3_time
       then DATEDIFF(mob3_time,limit_repay_time)
       else 0 end as mob3_overday
,case when  limit_repay_time <= mob4_time and TO_DATE(mob4_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob4_time,limit_repay_time)
       when limit_repay_time <= mob4_time and TO_DATE(mob4_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob4_time
       then DATEDIFF(mob4_time,limit_repay_time)
       else 0 end as mob4_overday
,case when  limit_repay_time <= mob5_time and TO_DATE(mob5_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob5_time,limit_repay_time)
       when limit_repay_time <= mob5_time and TO_DATE(mob5_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob5_time
       then DATEDIFF(mob5_time,limit_repay_time)
       else 0 end as mob5_overday
,case when  limit_repay_time <= mob6_time and TO_DATE(mob6_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob6_time,limit_repay_time)
       when limit_repay_time <= mob6_time and TO_DATE(mob6_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob6_time
       then DATEDIFF(mob6_time,limit_repay_time)
       else 0 end as mob6_overday
,case when  limit_repay_time <= mob7_time and TO_DATE(mob7_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob7_time,limit_repay_time)
       when limit_repay_time <= mob7_time and TO_DATE(mob7_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob7_time
       then DATEDIFF(mob7_time,limit_repay_time)
       else 0 end as mob7_overday
,case when  limit_repay_time <= mob8_time and TO_DATE(mob8_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob8_time,limit_repay_time)
       when limit_repay_time <= mob8_time and TO_DATE(mob8_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob8_time
       then DATEDIFF(mob8_time,limit_repay_time)
       else 0 end as mob8_overday
,case when  limit_repay_time <= mob9_time and TO_DATE(mob9_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob9_time,limit_repay_time)
       when limit_repay_time <= mob9_time and TO_DATE(mob9_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob9_time
       then DATEDIFF(mob9_time,limit_repay_time)
       else 0 end as mob9_overday
,case when  limit_repay_time <= mob10_time and TO_DATE(mob10_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob10_time,limit_repay_time)
       when limit_repay_time <= mob10_time and TO_DATE(mob10_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob10_time
       then DATEDIFF(mob10_time,limit_repay_time)
       else 0 end as mob10_overday
,case when  limit_repay_time <= mob11_time and TO_DATE(mob11_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob11_time,limit_repay_time)
       when limit_repay_time <= mob11_time and TO_DATE(mob11_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob11_time
       then DATEDIFF(mob11_time,limit_repay_time)
       else 0 end as mob11_overday
,case when  limit_repay_time <= mob12_time and TO_DATE(mob12_time,'yyyy-mm-dd') < GETDATE() and repay_time is null  
       then DATEDIFF(mob12_time,limit_repay_time)
       when limit_repay_time <= mob12_time and TO_DATE(mob12_time,'yyyy-mm-dd') < GETDATE() and repay_time is not NULL and repay_time > mob12_time
       then DATEDIFF(mob12_time,limit_repay_time)
       else 0 end as mob12_overday
-- ,if(repay_time > mob1_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo1
-- ,if(repay_time > mob2_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo2
-- ,if(repay_time > mob3_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo3
-- ,if(repay_time > mob4_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo4
-- ,if(repay_time > mob5_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo5
-- ,if(repay_time > mob6_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo6
-- ,if(repay_time > mob7_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo7
-- ,if(repay_time > mob8_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo8
-- ,if(repay_time > mob9_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo9
-- ,if(repay_time > mob10_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo10
-- ,if(repay_time > mob11_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo11
-- ,if(repay_time > mob12_time or repay_time is null,limit_capital+limit_interest*0.06+(limit_capital-cost/stagin_count)*0.06,0) as sy_amo12
,if(repay_time > mob1_time or repay_time is null,limit_capital,0) as sy_amo1
,if(repay_time > mob2_time or repay_time is null,limit_capital,0) as sy_amo2
,if(repay_time > mob3_time or repay_time is null,limit_capital,0) as sy_amo3
,if(repay_time > mob4_time or repay_time is null,limit_capital,0) as sy_amo4
,if(repay_time > mob5_time or repay_time is null,limit_capital,0) as sy_amo5
,if(repay_time > mob6_time or repay_time is null,limit_capital,0) as sy_amo6
,if(repay_time > mob7_time or repay_time is null,limit_capital,0) as sy_amo7
,if(repay_time > mob8_time or repay_time is null,limit_capital,0) as sy_amo8
,if(repay_time > mob9_time or repay_time is null,limit_capital,0) as sy_amo9
,if(repay_time > mob10_time or repay_time is null,limit_capital,0) as sy_amo10
,if(repay_time > mob11_time or repay_time is null,limit_capital,0) as sy_amo11
,if(repay_time > mob12_time or repay_time is null,limit_capital,0) as sy_amo12
from filtered_repayinfo_shl
;

select count(*) from tmp_repayinfo_shl;


-- 整笔组合
set odps.sql.type.system.odps2=true;
drop table if exists tmp_repayinfo2_shl;
create table tmp_repayinfo2_shl as
select order_code
, effect_time
, id_num
, usertype
, ctggrade
, ctg
, staging_amo
, stagin_count
, art_name
, apr
, irr
-- , any_value(cost) as cost
-- , sum(limit_interest) as limit_interest
, any_value(mob1_time) as mob1_time
, any_value(mob2_time) as mob2_time
, any_value(mob3_time) as mob3_time
, any_value(mob4_time) as mob4_time
, any_value(mob5_time) as mob5_time
, any_value(mob6_time) as mob6_time
, any_value(mob7_time) as mob7_time
, any_value(mob8_time) as mob8_time
, any_value(mob9_time) as mob9_time
, any_value(mob10_time) as mob10_time
, any_value(mob11_time) as mob11_time
, any_value(mob12_time) as mob12_time
,max(mob1_overday) as yq_day1
,max(mob2_overday) as yq_day2
,max(mob3_overday) as yq_day3
,max(mob4_overday) as yq_day4
,max(mob5_overday) as yq_day5
,max(mob6_overday) as yq_day6
,max(mob7_overday) as yq_day7
,max(mob8_overday) as yq_day8
,max(mob9_overday) as yq_day9
,max(mob10_overday) as yq_day10
,max(mob11_overday) as yq_day11
,max(mob12_overday) as yq_day12
,sum(sy_amo1) as jq1
,sum(sy_amo2) as jq2
,sum(sy_amo3) as jq3
,sum(sy_amo4) as jq4
,sum(sy_amo5) as jq5
,sum(sy_amo6) as jq6
,sum(sy_amo7) as jq7
,sum(sy_amo8) as jq8
,sum(sy_amo9) as jq9
,sum(sy_amo10) as jq10
,sum(sy_amo11) as jq11
,sum(sy_amo12) as jq12
from tmp_repayinfo_shl
group by order_code
, effect_time
, id_num
, usertype
, ctggrade
, ctg
, staging_amo
, stagin_count
, art_name
, apr
, irr
;

select count(*) from tmp_repayinfo2_shl;


-- vintage
drop table if exists tmp_vintage_shl;
create table tmp_vintage_shl as 
select 
ctggrade
, substr(effect_time, 1, 7) as 放款时间
, sum(staging_amo) as 放款金额
-- , nvl(sum(case when yq_day1>=30 then jq1 end), 0)/sum(case when TO_DATE(mob1_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob1
-- , nvl(sum(case when yq_day2>=30 then jq2 end), 0)/sum(case when TO_DATE(mob2_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob2
-- , nvl(sum(case when yq_day3>=30 then jq3 end), 0)/sum(case when TO_DATE(mob3_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob3
-- , nvl(sum(case when yq_day4>=30 then jq4 end), 0)/sum(case when TO_DATE(mob4_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob4
-- , nvl(sum(case when yq_day5>=30 then jq5 end), 0)/sum(case when TO_DATE(mob5_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob5
-- , nvl(sum(case when yq_day6>=30 then jq6 end), 0)/sum(case when TO_DATE(mob6_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob6
-- , nvl(sum(case when yq_day7>=30 then jq7 end), 0)/sum(case when TO_DATE(mob7_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob7
-- , nvl(sum(case when yq_day8>=30 then jq8 end), 0)/sum(case when TO_DATE(mob8_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob8
-- , nvl(sum(case when yq_day9>=30 then jq9 end), 0)/sum(case when TO_DATE(mob9_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob9
-- , nvl(sum(case when yq_day10>=30 then jq10 end), 0)/sum(case when TO_DATE(mob10_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob10
-- , nvl(sum(case when yq_day11>=30 then jq11 end), 0)/sum(case when TO_DATE(mob11_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob11
-- , nvl(sum(case when yq_day12>=30 then jq12 end), 0)/sum(case when TO_DATE(mob12_time,'yyyy-mm-dd') < GETDATE() then staging_amo+limit_interest*0.06+(staging_amo-cost)*0.06 end) as mob12
, nvl(sum(case when yq_day1>=30 then jq1 end), 0)/sum(case when TO_DATE(mob1_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob1
, nvl(sum(case when yq_day2>=30 then jq2 end), 0)/sum(case when TO_DATE(mob2_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob2
, nvl(sum(case when yq_day3>=30 then jq3 end), 0)/sum(case when TO_DATE(mob3_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob3
, nvl(sum(case when yq_day4>=30 then jq4 end), 0)/sum(case when TO_DATE(mob4_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob4
, nvl(sum(case when yq_day5>=30 then jq5 end), 0)/sum(case when TO_DATE(mob5_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob5
, nvl(sum(case when yq_day6>=30 then jq6 end), 0)/sum(case when TO_DATE(mob6_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob6
, nvl(sum(case when yq_day7>=30 then jq7 end), 0)/sum(case when TO_DATE(mob7_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob7
, nvl(sum(case when yq_day8>=30 then jq8 end), 0)/sum(case when TO_DATE(mob8_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob8
, nvl(sum(case when yq_day9>=30 then jq9 end), 0)/sum(case when TO_DATE(mob9_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob9
, nvl(sum(case when yq_day10>=30 then jq10 end), 0)/sum(case when TO_DATE(mob10_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob10
, nvl(sum(case when yq_day11>=30 then jq11 end), 0)/sum(case when TO_DATE(mob11_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob11
, nvl(sum(case when yq_day12>=30 then jq12 end), 0)/sum(case when TO_DATE(mob12_time,'yyyy-mm-dd') < GETDATE() then staging_amo end) as mob12
from tmp_repayinfo2_shl
group by 
ctggrade
, substr(effect_time, 1, 7)
order by 
ctggrade
, substr(effect_time, 1, 7)
;

select * from tmp_vintage_shl;


-- fpd
select 
-- usertype
-- , ctggrade
-- a.stagin_count
substr(a.effect_time, 1, 7) as 放款时间
, sum(case when fpd3_ind=1 then a.staging_amo end)/sum(case when fd3_ind=1 then a.staging_amo end) as fpd3
, sum(case when fpd7_ind=1 then a.staging_amo end)/sum(case when fd7_ind=1 then a.staging_amo end) as fpd7
, sum(case when fpd15_ind=1 then a.staging_amo end)/sum(case when fd15_ind=1 then a.staging_amo end) as fpd15
, sum(case when fpd30_ind=1 then a.staging_amo end)/sum(case when fd30_ind=1 then a.staging_amo end) as fpd30
from (select * from filtered_repayinfo_shl where period=1) a
inner join (select * from bt_order_loan_back_info where dt=0000) b
on a.order_code=b.order_code
group by 
-- usertype
-- , ctggrade
-- a.stagin_count
substr(a.effect_time, 1, 7)
order by 
-- usertype
-- , ctggrade
-- a.stagin_count
substr(a.effect_time, 1, 7)
;


-- 进件
-- 筛选订单
set odps.sql.type.system.odps2=true;
drop table if exists filtered_order_shl;
create table filtered_order_shl as
select * from (
select a.* 
-- , case when a.order_time<=minlimitrepaytime then 'new' else 'old' end as usertype
, case when a.user_type='new_1' then 'new' else 'old' end as usertype
, case when a.order_code_pre in (10,12,13,20,26,32,34,36,38,60,61,62,63,65,66,67,68,69,17,71,72,75,76,40,41,42,43,44,45,46,64,19) then '商品'
       when a.order_code_pre in (33,39,25,27,51,52,53,54,18) then '借款' else '其他' end as productline
, case when nvl(category_two_name_new, standard_category_2) in ('金银投资','黄金','二手手机通讯') then '高风险套现'
    when nvl(category_two_name_new, standard_category_2) in ('手机', '电脑整机','影音娱乐','智能设备','腕表','流行男鞋','白酒','电脑组件') then '易套现'
    when a.order_code_pre in (33,39,25,27,51,52,53,54,18) then '借款'
    -- when a.order_code_pre=36 then '虚拟正常品类'
    when nvl(category_two_name_new, standard_category_2) is null or nvl(category_two_name_new, standard_category_2) in ('','NULL') then '空值'
    -- else '非虚拟正常品类' end as ctggrade
    else '正常品类' end as ctggrade
, nvl(category_two_name_new, standard_category_2) as ctg
, apr
, irr
from (select * from basestone_dp.bt_order_bas_info where dt=0000) a
left join basestone_dp_dev.bi_order_category_info b
on a.order_code=b.order_code
left join basestone_dp.bt_order_loan_rate_calc h
on a.order_code=h.order_code
where a.order_time between '2022-01-01' and '2023-01-31'
)
where productline='商品'
;

select count(*) from filtered_order_shl;


-- 通过率
drop table if exists tmp_pass_shl;
create table tmp_pass_shl as
select 
ctggrade
, substr(order_time, 1, 7) as 月份
, count(case when cloud_rc_result not like '%Review%' or cloud_rc_result is null then order_code end) as 机审进件数
, count(case when cloud_rc_result like '%Accept%' then order_code end)/count(case when cloud_rc_result not like '%Review%' or cloud_rc_result is null then order_code end) as 机审订单通过率
, sum(case when cloud_rc_result not like '%Review%' or cloud_rc_result is null then staging_amo end) as 机审进件金额
, sum(case when cloud_rc_result like '%Accept%' then staging_amo end)/sum(case when cloud_rc_result not like '%Review%' or cloud_rc_result is null then staging_amo end) as 机审金额通过率
from filtered_order_shl
group by 
ctggrade
, substr(order_time, 1, 7)
order by 
ctggrade
, substr(order_time, 1, 7)
;

select * from tmp_pass_shl;


-- 合并表
select a.*
, 放款金额, mob1, mob2, mob3, mob4, mob5, mob6, mob7, mob8, mob9, mob10, mob11, mob12
from tmp_pass_shl a
left join tmp_vintage_shl b
on a.月份=b.放款时间
and a.ctggrade=b.ctggrade
;
