
Home > 
 > Blank Query
### สร้างตาราง
let
    Source = CustomerFeedback, // ตรวจสอบว่าชื่อตารางหลักของคุณชื่อนี้
    AllComments = Text.Lower(Text.Combine(Source[Comment], " ")),
    GoodWords = {"happy", "satisfied", "delicious", "amazing", "love", "excellent", "great", "enjoyed", "recommend", "best"},
    BadWords = {"disappointed", "bad", "terrible", "awful", "hate", "worst", "horrible", "disgusting", "not good", "dislike"},
    
    FnCount = (w) => (Text.Length(AllComments) - Text.Length(Text.Replace(AllComments, w, ""))) / Text.Length(w),
    
    TableGood = Table.FromList(GoodWords, Splitter.SplitByNothing(), {"Word"}),
    AddGoodCount = Table.AddColumn(TableGood, "Count", each FnCount([Word])),
    AddGoodType = Table.AddColumn(AddGoodCount, "Category", each "Good"),
    
    TableBad = Table.FromList(BadWords, Splitter.SplitByNothing(), {"Word"}),
    AddBadCount = Table.AddColumn(TableBad, "Count", each FnCount([Word])),
    AddBadType = Table.AddColumn(AddBadCount, "Category", each "Bad"),
    
    Combined = Table.Combine({AddGoodType, AddBadType}),
    Final = Table.TransformColumnTypes(Combined,{{"Count", Int64.Type}})
in
    Final
-----------------------------------------------------------------------------------

WeekStart = 
'CustomerFeedback'[DateSubmitted] - WEEKDAY('CustomerFeedback'[DateSubmitted], 2) + 1

------------------------------------------------------------------------------------

Points_Earned = IF('LoyaltyProgramHistory'[Action] = "Points Earned",ABS('LoyaltyProgramHistory'[Points]), 0)

------------------------------------------------------------------------------------

Customer Earned Count = 
CALCULATE(COUNT('LoyaltyProgramHistory'[HistoryId]),'LoyaltyProgramHistory'[Action] = "Points Earned")

------------------------------------------------------------------------------------

Median Activity = MEDIANX(VALUES('LoyaltyProgramHistory'[CustomerId]),[Customer Earned Count])

------------------------------------------------------------------------------------

Days Since Last Upgrade = 
VAR CurrentCustomer = 'loyalty_program_history'[CustomerId]
VAR CurrentDate = 'loyalty_program_history'[Timestamp]

VAR PreviousUpgradeDate = 
    CALCULATE(
        MAX('loyalty_program_history'[Timestamp]),
        FILTER(
            'loyalty_program_history',
            'loyalty_program_history'[CustomerId] = CurrentCustomer &&
            'loyalty_program_history'[Action] = "Tier Upgrade" &&
            'loyalty_program_history'[Timestamp] < CurrentDate
        )
    )

RETURN
IF(
    'loyalty_program_history'[Action] = "Tier Upgrade" && NOT(ISBLANK(PreviousUpgradeDate)),
    DATEDIFF(PreviousUpgradeDate, CurrentDate, DAY),
    BLANK()
)

------------------------------------------------------------------------------------

TierLevel = 
VAR CustomerID = 'LoyaltyProgramHistory'[CustomerId]
RETURN
CALCULATE(
    COUNT('LoyaltyProgramHistory'[Action]),
    FILTER(
        'LoyaltyProgramHistory',
        'LoyaltyProgramHistory'[CustomerId] = CustomerID && 
        'LoyaltyProgramHistory'[Action] = "Tier Upgrade"
    )
) + 1
-------------------------------------------------------------------------------------
### อีกแบบ
TierLevel = 
VAR cusid = [CustomerId]
VAR c=
    CALCULATE(
        COUNT('LoyaltyProgramHistory'[Action]),
        FILTER(
            'LoyaltyProgramHistory',
            'LoyaltyProgramHistory'[Action] = "Tier Upgrade" && 'LoyaltyProgramHistory'[CustomerId] = cusid
        )
    )
RETURN 
    IF(ISBLANK(c),1,c)
-------------------------------------------------------------------

Tier Detail = 
VAR t = [Level]
RETURN 
SWITCH(TRUE(),
    t<=4,"Basic "&t,
    t<=8,"Silver "&t-4,
    t<=12,"Gold "&t-8,
    "Platinum"&t-12
)
-----------------------------------------------------------------------
ห
Tier_Order = 
SWITCH('LoyaltyProgramHistory'[Tier_Simplified],
    "Basic", 1,
    "Silver", 2,
    "Gold", 3,
    "Platinum", 4,
    5
)

-----------------------------------------------------------------------
DEFINE
    MEASURE 'LoyaltyProgramHistory'[Customer Earned Count] =
        CALCULATE(
            COUNT('LoyaltyProgramHistory'[HistoryId]),
            'LoyaltyProgramHistory'[Action] = "Points Earned"
        )
    MEASURE 'LoyaltyProgramHistory'[Median Activity] =
        MEDIANX(
            VALUES('LoyaltyProgramHistory'[CustomerId]),
            [Customer Earned Count]
        )


    MEASURE 'LoyaltyProgramHistory'[Avg Days Between Upgrades] =
        AVERAGEX(
            FILTER(
                'LoyaltyProgramHistory',
                'LoyaltyProgramHistory'[Action] = "Tier Upgrade"
            ),
            VAR cusid = 'LoyaltyProgramHistory'[CustomerId]
            VAR datetime = 'LoyaltyProgramHistory'[Timestamp]
            VAR per =
                CALCULATE(
                    MAX('LoyaltyProgramHistory'[Timestamp]),
                    ALL('LoyaltyProgramHistory'),
                    'LoyaltyProgramHistory'[CustomerId] = cusid,
                    'LoyaltyProgramHistory'[Action] = "Tier Upgrade",
                    'LoyaltyProgramHistory'[Timestamp] < datetime
                )
            RETURN
                IF(NOT ISBLANK(per), DATEDIFF(per, datetime, DAY))
        )


    MEASURE 'LoyaltyProgramHistory'[Avg Days Earn To Redeem] =
        AVERAGEX(
            FILTER(
                'LoyaltyProgramHistory',
                'LoyaltyProgramHistory'[Action] = "Points Redeemed"
            ),
            VAR CurrentCustomer = 'LoyaltyProgramHistory'[CustomerId]
            VAR RedeemTime = 'LoyaltyProgramHistory'[Timestamp]
            VAR LastEarnTime =
                CALCULATE(
                    MAX('LoyaltyProgramHistory'[Timestamp]),
                    ALL('LoyaltyProgramHistory'),
                    'LoyaltyProgramHistory'[CustomerId] = CurrentCustomer,
                    'LoyaltyProgramHistory'[Action] = "Points Earned",
                    'LoyaltyProgramHistory'[Timestamp] < RedeemTime
                )
            RETURN
                IF(
                    NOT ISBLANK(LastEarnTime),
                    VALUE(RedeemTime - LastEarnTime)
                )
        )
    MEASURE 'CustomerFeedback'[Comment_Sentiment_Logic] =
        VAR CurrentComment = SELECTEDVALUE('CustomerFeedback'[Comment])
       
        VAR CountGood = SUMX(FILTER('count', 'count'[Category] = "Good"), IF(CONTAINSSTRING(CurrentComment, 'count'[Word]), 1, 0))
        VAR CountBad = SUMX(FILTER('count', 'count'[Category] = "Bad"), IF(CONTAINSSTRING(CurrentComment, 'count'[Word]), 1, 0))
       
        RETURN
            IF(ISBLANK(CurrentComment), "Neutral",
                IF(CountGood > CountBad, "Positive",
                    IF(CountBad > CountGood, "Negative", "Neutral")
                )
            )


EVALUATE(
    SUMMARIZECOLUMNS(
        "Median Earn Activity", [Median Activity],
        "Avg Days Upgrade", [Avg Days Between Upgrades],
        "Avg Days Redeem", [Avg Days Earn To Redeem]
    ))
EVALUATE(
    TOPN(100, 'CustomerFeedback'))
