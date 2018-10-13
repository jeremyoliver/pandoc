{-# LANGUAGE OverloadedStrings #-}
module Tests.Readers.Man (tests) where

import Prelude
import Data.Text (Text)
import Test.Tasty
import Tests.Helpers
import Text.Pandoc
import Text.Pandoc.Arbitrary ()
import Text.Pandoc.Builder
import Text.Pandoc.Readers.Man

man :: Text -> Pandoc
man = purely $ readMan def

infix 4 =:
(=:) :: ToString c
     => String -> (Text, c) -> TestTree
(=:) = test man

tests :: [TestTree]
tests = [
  -- .SH "HEllo bbb" "aaa"" as"
  testGroup "Macros" [
      "Bold" =:
      ".B foo"
      =?> (para $ strong "foo")
    , "Italic" =:
      ".I bar\n"
      =?> (para $ emph "bar")
    , "BoldItalic" =:
      ".BI foo bar"
      =?> (para $ strong $ emph $ str "foo bar")
    , "H1" =:
      ".SH The header\n"
      =?> header 2 (str "The" <> space <> str "header")
    , "H2" =:
      ".SS \"The header 2\""
      =?> header 3 (str "The header 2")
    , "Macro args" =:
      ".B \"single arg with \"\"Q\"\"\""
      =?> (para $ strong $ str "single arg with \"Q\"")
    , "comment" =:
      ".\\\"bla\naaa"
      =?> (para $ space <> str "aaa")
    , "link" =:
      ".BR aa (1)"
      =?> (para $ fromList [Link nullAttr [Strong [Str "aa"]] ("../1/aa.1","aa"), Strong [Str " (1)",Str ""]])
    ],
  testGroup "Escapes" [
      "fonts" =:
      "aa\\fIbb\\fRcc"
      =?> (para $ str "aa" <> (emph $ str "bb") <> str "cc")
    , "skip" =:
      "a\\%\\{\\}\\\n\\:b\\0"
      =?> (para $ fromList $ map Str ["a", "b"])
    , "replace" =:
      "\\-\\ \\\\\\[lq]\\[rq]\\[em]\\[en]\\*(lq\\*(rq"
      =?> (para $ fromList $ map Str ["-", " ", "\\", "“", "”", "—", "–", "«", "»"])
    , "replace2" =:
      "\\t\\e\\`\\^\\|\\'"
      =?> (para $ fromList $ map Str ["\t", "\\", "`", " ", " ", "`"])
    ],
  testGroup "Lists" [
      "bullet" =:
      ".IP\nfirst\n.IP\nsecond"
      =?> bulletList [plain $ str "first", plain $ str "second"]
    , "odrered" =:
      ".IP 1 a\nfirst\n.IP 2 a\nsecond"
      =?> orderedListWith (1,Decimal,DefaultDelim) [plain $ str "first", plain $ str "second"]
    , "upper" =:
      ".IP A a\nfirst\n.IP B a\nsecond"
      =?> orderedListWith (1,UpperAlpha,DefaultDelim) [plain $ str "first", plain $ str "second"]
    , "nested" =:
      ".IP\nfirst\n.RS\n.IP\n1a\n.IP\n1b\n.RE"
      =?> fromList [BulletList [[Plain [Str "first"],BulletList [[Plain [Str "1a"]],[Plain [Str "1b"]]]]]]
    ],
  testGroup "CodeBlocks" [
      "cb1"=:
      ".nf\naa\n\tbb\n.fi"
      =?> codeBlock "aa\n\tbb"
    ]
  ]
