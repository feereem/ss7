set identity_insert LoyaltyProgramHistory on;
insert into LoyaltyProgramHistory(HistoryId,CustomerId,Action,Points,Timestamp)
select HistoryId,CustomerId,Action,Points,Timestamp
from loyalty_program_history
where Action='Tier Upgrade' OR Action='Points Redeemed' OR Action='Points Earned'
set identity_insert LoyaltyProgramHistory off;

set identity_insert SocialMediaEngagement on;
insert into SocialMediaEngagement(EngagementId,Platform,PostType,Reach,Impressions,EngagementCount,Date)
select EngagementId,Platform,PostType,Reach,Impressions,EngagementCount,Date
from social_media_engagement
where EngagementCount>=0 and Impressions>=0 and Reach>=0
set identity_insert SocialMediaEngagement off;

set identity_insert WebsiteAnalytics on;
insert into WebsiteAnalytics(AnalyticsId,Date,PageViews,UniqueVisitors,BounceRate,AverageSessionDuration)
select AnalyticsId,Date,PageViews,UniqueVisitors,BounceRate,AverageSessionDuration
from website_analytics
where (BounceRate>=0 AND BounceRate<=100) and PageViews>=0 and UniqueVisitors>=0
set identity_insert WebsiteAnalytics off;
