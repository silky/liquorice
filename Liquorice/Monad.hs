{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_HADDOCK prune #-}

{-|
Module      : Liquorice.Monad
Description : Liquorice functions under the `State` Monad.
Copyright   : © Jonathan Dowland, 2020
License     : GPL-3
Maintainer  : jon+hackage@dow.land
Stability   : experimental
Portability : POSIX

Core `Liquorice` functions for building maps. These are all under the
`State` Monad, the state which is passed around is the `Context` being
operated on.

These functions are wrapped versions of those in `Liquorice.Pure`. The
wrapped versions are generated by Template Haskell expressions defined
in Liquorice.Monad.TH.
-}
module Liquorice.Monad where

import Control.Monad.State.Lazy
import Control.Monad
import Language.Haskell.TH hiding (location)

import Liquorice
import qualified Liquorice.Pure as P
import Liquorice.Monad.TH

-- injects monadic-wrapped versions of the functions from Liquorice.Pure
wrapPureFunctions

-- | Evaluate the supplied State Context to produce a pure Context. In other words,
-- run the supplied Liquorice DSL program and calculate the resulting structure.
runWadL x = snd $ runState x start

-- | Repeat an action 9 times, spaced out by the provided distance.
cluster stuff dist = do
  turnaround
  step dist dist
  turnaround
  pushpop $ triple $ do
    pushpop $ triple $ do
        stuff
        step dist 0
    step 0 dist

-- | Repeat an action 8 times, centered around the origin and spaced
-- out by the provided distance.
surround stuff dist = do
    pushpop $ do
        step (negate dist) (negate dist)
        quad $ do
            twice $ do
                stuff
                step dist 0
            stuff
            turnright

-- | Obtain the current Pen location and orientation in a tuple.
getLoc :: State Context (Point, Orientation)
getLoc = do
    ctx <- get
    return (location ctx, orientation ctx)

-- | Set the current Pen location and orientation from a tuple.
setLoc :: (Point, Orientation) -> State Context ()
setLoc (p,o) = do
    ctx <- get
    put ctx { location = p, orientation = o }

-- | getLoc but at provided x/y offset.
getLocAt x y = do
    step x y
    l <- getLoc
    step (negate x) (negate y)
    return l

-- | Add the current buffer of linedefs to the last-defined Sector.
extendsector :: State Context ()
extendsector = do
    old <- get
    let lines = linedefs old
        olds  = head (sectors old)
        news  = olds { sectorLines = sectorLines olds ++ lines }
        new   = old { sectors = news : (tail (sectors old)), linedefs = [] }
    put new
