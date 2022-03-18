use dermsl_prod;




Select a.ruleGroupName as GroupsThatShouldBeTermed, a.GroupStartDatetime, a.groupEnddatetime
, ActiveEligibles_ByActiveFlag = Count(Distinct Case when b.Activeflag = 1 then membersignupdataid else null end) 
,ActiveEligiblesByCancelledDatetime = Count(Distinct Case when b.CancelledDatetime > getdate() or b.cancelledDatetime is  null  then membersignupdataid else null end) 
,ActiveAccounts = Count(distinct case when m.Activememberflag = 1 then m.memberid else null end) 
From   LookupRuleGroup a 
       Left join Membersignupdata b
              On a.Lookuprulegroupid = b.LookupRuleGroupid
       Left join (MemberruleGroup mrg inner join member m on mrg.memberid = m.memberid ) 
              ON mrg.LookupRuleGroupid = a.LookupRulegroupid
where a.offercode in 
(
'5400-3593'
,'5400-3668'
,'5400-3694'
,'5400-3699'
,'5400-3711'
,'5400-3742'
,'5400-3763'
,'5400-3771'
,'5400-3777'
,'5400-3793'
,'5400-3824'
,'5400-3838' 
,'5400-3902'
,'5400-3910'
,'5400-3939'
,'5400-3952'
,'5400-3960'
,'5400-3971'
,'5400-3983'
,'5400-3987'
,'5400-4070'
,'5400-3124'
,'5400-3166'
,'5400-3167'
,'5400-3168'
,'5400-3177'
,'5400-3197'
,'5400-3198'
,'5400-3236'
,'5400-3274'
,'5400-3285'
,'5400-3289'
,'5400-3291'
,'5400-3313'
,'5400-3328'
,'5400-3420'
,'5400-3427'
,'5400-3430'
,'5400-3515'
,'5400-3519'
,'5400-3577'
,'5400-2648'
,'5400-2653'
,'5400-2685'
,'5400-2713'
,'5400-2735'
,'5400-2780'
,'5400-2805'
,'5400-2812'
,'5400-2823'
,'5400-2829'
,'5400-2849'
,'5400-2850'
,'5400-2851'
,'5400-2884'
,'5400-2893'
,'5400-2899'
,'5400-2925'
,'5400-2932'
,'5400-2934'
,'5400-2945'
,'5400-2957'
,'5400-3008'
,'5400-3033'
,'5400-3036'
,'5400-3059'
,'5400-3062'
,'5400-3085'
,'5400-3098'
,'5400-6435'
,'5400-6475'
,'5400-6477'
,'5400-6630'
,'5400-1362'
,'5400-2016'
,'5400-2029'
,'5400-2046'
,'5400-2056'
,'5400-2058'
,'5400-2065'
,'5400-2091'
,'5400-2106'
,'5400-2116'
,'5400-2139'
,'5400-2149'
,'5400-2169'
,'5400-2202'
,'5400-2204'
,'5400-2227'
,'5400-2270'
,'5400-2323'
,'5400-2350'
,'5400-2373'
,'5400-2396'
,'5400-2400'
,'5400-2413'
,'5400-2419'
,'5400-2443'
,'5400-2452'
,'5400-2594'
,'5400-5829'
,'5400-5901'
,'5400-5935'
,'5400-6212'
,'5400-5274'
,'5400-5293'
,'5400-5309'
,'5400-5459'
,'5400-5500'
,'5400-5720'
,'5400-5040'
,'5400-5067'
,'5400-5099'
,'5400-5106'
,'5400-5140'
,'5400-5182'
,'5400-5238'
,'5400-4079'
,'5400-4098'
,'5400-4106'
,'5400-4127'
,'5400-4128'
,'5400-4137'
,'5400-4170'
,'5400-4198'
,'5400-4214'
,'5400-4227'
,'5400-4251'
,'5400-4275'
,'5400-4298'
,'5400-4310'
,'5400-4315'
,'5400-4322'
,'5400-4330'
,'5400-4334'
,'5400-4342'
,'5400-4384'
,'5400-4394'
,'5400-4399'
,'5400-4410'
,'5400-4423'
,'5400-4424'
,'5400-4427'
,'5400-4438'
,'5400-4450'
,'5400-4452'
,'5400-4517'
,'5400-4542'
,'5400-4557'
,'5400-4580'
,'5400-4584'
,'5400-2613'
,'5400-4366'
,'5400-3861'
,'5400-3304'
,'5400-3905'
,'5400-2855'
,'5400-4528'
,'5400-3410'
,'5400-3588'
,'5400-2789'
,'5400-4339'
,'5400-2048'
,'5400-3479'
,'5400-4110'
,'5400-3222'
,'5400-3235'
,'5400-3264'
,'5400-3760'
,'5400-2530'
,'5400-3336'
,'5400-3393'
,'5400-4407'
,'5400-3058'
,'5400-4162'
,'5400-4118'


)
group by a.ruleGroupName, a.GroupStartDatetime, a.groupEnddatetime



Select a.ruleGroupName as GroupsThatShouldBeTermed, a.GroupStartDatetime, a.groupEnddatetime
, ActiveEligibles_ByActiveFlag = Count(Distinct Case when b.Activeflag = 1 then membersignupdataid else null end) 
,ActiveEligiblesByCancelledDatetime = Count(Distinct Case when b.CancelledDatetime > getdate() or b.cancelledDatetime is  null  then membersignupdataid else null end) 
,ActiveAccounts = Count(distinct case when m.Activememberflag = 1 then m.memberid else null end) 
From   LookupRuleGroup a 
       Left join Membersignupdata b
              On a.Lookuprulegroupid = b.LookupRuleGroupid
       Left join (MemberruleGroup mrg inner join member m on mrg.memberid = m.memberid ) 
              ON mrg.LookupRuleGroupid = a.LookupRulegroupid
where a.offercode in 
('5400-3313'
)
group by a.ruleGroupName, a.GroupStartDatetime, a.groupEnddatetime

select msd.CancelledDateTime, *
       from MEMBERSignupData msd
       inner join LOOKUPRuleGroup rg on msd.LOOKUPRuleGroupID = rg.LOOKUPRuleGroupID
where rg.OfferCode  = '5400-3313'



select m.CancelledDateTime, m.ActiveMEMBERFlag, *
       from MEMBER m
       inner join MEMBERRuleGroup mrg on m.MEMBERID = mrg.MEMBERID
       inner join LOOKUPRuleGroup rg on mrg.LOOKUPRuleGroupID = rg.LOOKUPRuleGroupID
where rg.OfferCode  = '5400-3313'
