--
-- Human exchangable identifiers and locators
--
-- Copyright © 2011-2014 Operational Dynamics Consulting, Pty Ltd
--
-- The code in this file, and the program it is a part of, is
-- made available to you by its authors as open source software:
-- you can redistribute it and/or modify it under the terms of
-- the BSD licence.
--
-- This code originally licenced GPLv2. Relicenced BSD3 on 2 Jan 2014.
--

{-# LANGUAGE OverloadedStrings #-}

module Data.Locator.Hashes
(
    hashStringToBase62
) where


import Prelude hiding (toInteger)

import Crypto.Hash.SHA1 as Crypto
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as S
import Data.Char (chr, isDigit, isLower, isUpper, ord)
import Data.Word
import Numeric (showIntAtBase)

--
-- Conversion between decimal and base 62
--

represent :: Int -> Char
represent x
    | x < 10 = chr (48 + x)
    | x < 36 = chr (65 + x - 10)
    | x < 62 = chr (97 + x - 36)
    | otherwise = '@'

toBase62 :: Integer -> String
toBase62 x =
    showIntAtBase 62 represent x ""

padWithZeros :: Int -> Integer -> String
padWithZeros digits x =
    pad ++ str
  where
    pad = take len (replicate digits '0')
    len = digits - length str
    str = toBase62 x


value :: Char -> Int
value c
    | isDigit c = ord c - 48
    | isUpper c = ord c - 65 + 10
    | isLower c = ord c - 97 + 36
    | otherwise = 0

multiply :: Int -> Char -> Int
multiply acc c =
    acc * 62 + value c

decode :: String -> Int
decode ss =
    foldl multiply 0 ss


--
-- Given a URL, convert it into a 5 character hash.
--

toWords :: String -> [Word8]
toWords cs =
    map fn cs
  where
    fn :: Char -> Word8
    fn c = fromIntegral $ fromEnum c

concatToInteger :: [Word8] -> Integer
concatToInteger bytes =
    foldl fn 0 bytes
  where
    fn acc b = (acc * 256) + (fromIntegral b)

digest :: String -> Integer
digest ws =
    i
  where
    i  = concatToInteger h
    h  = B.unpack h'
    h' = Crypto.hash x'
    x' = S.pack ws


--
-- | Take an arbitrary string, hash it, then padWithZeros it as a short
-- @digits@-long base62 string.
--
hashStringToBase62 :: Int -> S.ByteString -> S.ByteString
hashStringToBase62 digits s' =
    r'
  where
    s = S.unpack s'
    n  = digest s               -- SHA1 hash
    limit = 62 ^ digits
    x  = mod n limit            -- trim to specified number base62 chars
    r  = padWithZeros digits x  -- convert to String
    r' = S.pack r

