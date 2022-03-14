{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, ConstraintKinds, InstanceSigs, LambdaCase, FlexibleContexts, DefaultSignatures, FlexibleInstances #-}
module DataType where

import Data.Function
import Data.List 
import Data.Maybe 
import GaleShapley 
import ImplementStableRoommate
import Info 
import qualified Data.Map as M 
import MatchDatatype
import SerialDictatorship


data Level =  VLow | Low | Med | High | VHigh deriving (Eq,Ord,Show)
type Rating = Int -- 1 to 10 with 10 being highest

data Rank = Rank {unRank :: Int} 
rank = Just . Rank
-- =============================================================================================

(-->) :: a -> b -> (a,b)
(-->) x y = (x,y)

every :: Capacity -> a -> Capacity
every c _ = c 

class  (Bounded a,Enum a,Ord a) => Set a where
    members :: [a]
    members = enumFromTo minBound maxBound

    capacity :: a -> Capacity  
    capacity = every 1


-- instance (Show a,Show b) => Show (Match a b) where
--     show = concatMap f . unMatch  
--         where 
--             f (x,y,z) = show x ++ ": \n\t\t Matched with " ++ show y
--                         ++ "\n\t\t Remaining capacity: " ++ show z ++ "\n"
     
sortSnd :: Ord c => [(b,Maybe c)] -> [b]
sortSnd = map fst . reverse . sortBy (compare `on` (fromJust.snd))

type Val o a = Info o a [Double]

{-decomposed ::  (Ord a,Norm b) => Info o a b -> Val o a 
decomposed = mapInfo components -}

rankOrder :: (Set a,Set b,Norm c,Ord b) => Info a b c -> Match a b 
rankOrder = Match . map (\(x,y) -> (x,sortSnd y,capacity x)) . fromInfo . mapInfo norm
     
class Relate a b c | a b -> c where
    gather :: Info a b c 


-- class Norm a where
--     -- components :: a -> [Double]
--     -- components _ = []

--     norm :: a ->  Double
--     -- norm = sum . components

-- instance Norm Rank where
--     norm (Rank r) = (1/fromIntegral r)

-- instance Norm Bool where
--     norm = \case {False -> 0.0 ; True -> 1.0 } 

-- instance Norm (Double,Double) where
--     norm (v,lv) = min (v/lv) 1   

-- instance Norm (Int,Int) where
--     norm (v,lv) = min (fromIntegral v/fromIntegral lv) 1

-- instance Norm (Double,Int) where
--     norm (v,lv) = min (v/fromIntegral lv)  1 

-- instance Norm (Int,Double) where
    -- norm (v,lv) = min (fromIntegral v/lv) 1 


class Norm a where
    components :: a -> [Double]
    components _ = []

    norm :: a -> Maybe Double -> Double
    norm x _ = sum . components $ x

instance Norm Rank where
    norm (Rank r) Nothing = (1/fromIntegral r)

instance Norm Bool where
    norm r Nothing = case x of {False -> 0.0 ; True -> 1.0} 

instance Norm Double where
    norm v lv = min (v/lv) 1   

instance Norm Int where
    norm v lv = min (fromIntegral v/lv) 1


with :: a -> b -> (a,Maybe b)
with x y = (x,Just y)

only :: a -> (a,Maybe b)
only x = (x,Nothing)

normAll :: [(a,Maybe b)] -> [Double]
normAll = map norm 

-- =================================================================================================
-- =================================================================================================

type SetNorm a b c d = (Set a,Set b,Norm c, Norm d)
type Set2 a b = (Set a,Set b)
type Norm2 a b = (Norm a,Norm b)
type Relate2 a b c d = (Relate a b c,Relate b a d)

choices :: (Ord a,Ord b) => [(a,[b])] -> Info a b Rank
choices = info . map (\(x,ys) -> (x,assocRanks ys))
    where assocRanks =  zipWith (\q p -> p --> Rank q) [1..] 


twoWayWithCapacity :: (Relate2 a b c d,Set2 a b,Norm2 c d) => CMatch a b
twoWayWithCapacity = CMatch $ map (\(p,(_,r,_,t)) -> (p,r,t)) ls 
    where
      ls = galeShapley (f x) (f y) 
      (x,y) = (rankOrder gather,rankOrder gather)
      f = map (\(a,b,c) -> (a,(b,[],c,c))) . unMatch 

twoWay :: (Relate2 a b c d,Set2 a b,Norm2 c d) => Match a b
twoWay = rmvCapacity twoWayWithCapacity

rmvCapacity :: CMatch a b -> Match a b 
rmvCapacity (CMatch ls) = Match $ map (\(p,r,c) -> (p,r,0)) ls


twoWayExpl :: (Relate2 a b c d,Set2 a b,Norm2 c d) => a -> b -> Match a b
twoWayExpl a b = Match $ map (\(p,(_,r,_,t)) -> if p == a then (p,b:r,t) else (p,r,t)) ls
    where 
        ls = galeShapley (f x') (f y') 
        (x,y) = (rankOrder gather,rankOrder gather)
        x1 = reducecapacity a 1 x 
        y1 = reducecapacity b 1 y
        x' = changepreferences (delete b) a x1 
        y' = changepreferences (delete a) b y1
        f = map (\(a,b,c) -> (a,(b,[],c,c))) . unMatch 

sameSet :: (Relate a a b,Set a,Norm b) => SameSetMatch a
sameSet = irvings $ rankOrder gather

oneWayWithCapacity :: (Relate a b c, Set2 a b,Norm c) => CMatch a b 
oneWayWithCapacity = CMatch $ unMatch $ serialAssignment members [] $ rankOrder gather

oneWay :: (Relate2 a b c d,Set2 a b,Norm2 c d) => Match a b
oneWay = rmvCapacity oneWayWithCapacity 

-- sameSetExpl :: (Relate a a b,Set a,Norm b) => a -> a -> SameSetMatch a 
-- sameSetExpl x y = case m2 of 
--                       Nothing -> Nothing 
--                       Just ms -> let Match ms' =  ms 
--                                  in Just $ Match $ (y,[x],0):(x,[y],0):ms'  
--     where m  = rankOrder gather
--           m1 = delPreference m 
--           m2 = irvings m1 

-- =================================================================================================
-- weight' :: [Double] -> [Double] -> [Double] 
-- weight' ws = zipWith (*) ws 

weight :: [(Double,Double)] ->  Double
weight xs = sum . zipWith (*) (map fst xs) $ (map snd xs)


evalL = \case {VLow -> 0.2; Low -> 0.4 ; Med -> 0.6 ; High -> 0.8 ; VHigh -> 1.0 } 
evalB = \case {False -> 0.0 ; True -> 1.0 } 

evalR :: Rating -> Double
evalR = \v -> (fromIntegral v)/10.0

expressCh :: (Set b,Norm c,Eq b) => [b] -> [Maybe c] -> (b -> Maybe c) 
expressCh bs cs b = cs !! i
    where i = (fromJust.elemIndex b) bs  

class Set b => Annotate a b | b -> a where
    labels :: [b]
    labels = members

-- ================================================================================================

class Schedule a b | a -> b where
    constraints :: Constraints a
    availability :: Info a b Rank  

data Quantifier  = All | Oneof | LeastOne

type Constraints a = [(Quantifier, [a])]