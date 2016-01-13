{-# LANGUAGE UnicodeSyntax #-}

import           Codec.Picture              (DynamicImage (..), readImage,
                                             writePng)
import qualified Pixs.Filter                as F
import qualified Pixs.Information.Histogram as H
import qualified Pixs.Transformation        as T
import qualified Pixs.Arithmetic            as Arith
import           Prelude                    hiding (error, flip)
import           System.Environment         (getArgs)
import qualified Options.Applicative        as A
import           Options.Applicative        (Parser, (<>))

data Command = Brightness String Int    String
             | Flip       String String
             | Add        String String String
             deriving (Eq, Read)

brightness ∷ Parser Command
brightness = let toInt x = (read x) ∷ Int
             in Brightness
                <$> A.strOption (   A.long "in"
                                 <> A.metavar "INPUT"
                                 <> A.help "Input image file to be transformed")
                <*> fmap toInt
                      (A.strOption
                        (   A.long "magnitude"
                         <> A.short 'm'
                         <> A.metavar "MAGNITUDE"
                         <> A.help "Magnitude of brightness change"))
                <*> A.strOption
                      (   A.long "out"
                       <> A.metavar "OUTPUT"
                       <> A.help "File name to write to.")

flip ∷ Parser Command
flip = Flip
    <$> A.strOption (  A.long "in"
                    <> A.metavar "INPUT"
                    <> A.help "Input image file to be transformed.")
    <*> A.strOption
    (   A.long "out"
     <> A.metavar "OUTPUT"
     <> A.help "File name to write to.")

add ∷ Parser Command
add = Add
    <$> A.strOption (   A.long "img1"
                     <> A.metavar "OPERAND₁"
                     <> A.help "First operand image")
    <*> A.strOption (   A.long "img2"
                     <> A.metavar "OPERAND₂"
                     <> A.help "Second operand image")
    <*> A.strOption (   A.long "out"
                     <> A.metavar "OUTPUT"
                     <> A.help "File name to write to.")

menu ∷ Parser Command
menu = A.subparser
         $  A.command "brightness"
             (A.info brightness
                      (A.progDesc "Change brightness of given image."))
         <> A.command "flip"
             (A.info flip
                      (A.progDesc "Flip a given image about the origin."))
         <> A.command "add"
             (A.info add
                     (A.progDesc "Add two images together."))

run ∷ Command → IO ()
run (Brightness inFile n outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left error  → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                         $ T.changeBrightness n img
run (Flip inFile outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left  error → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                         $ T.flip img
run (Add img₁ img₂ outFile) = do
  imgLoad₁ ← readImage img₁
  imgLoad₂ ← readImage img₂
  case [imgLoad₁, imgLoad₂] of
    [Right (ImageRGBA8 img₁), Right (ImageRGBA8 img₂)] →
      writePng outFile
      $ Arith.add img₁ img₂
    _ → putStrLn "An error has occured."

main ∷ IO ()
main = let opts = A.info (A.helper <*> menu)
                  (   A.fullDesc
                   <> A.progDesc "Process images."
                   <> A.header "pixs")
       in A.execParser opts >>= run
