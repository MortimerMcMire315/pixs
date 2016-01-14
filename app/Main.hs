{-# LANGUAGE UnicodeSyntax #-}

import           Data.Either                (partitionEithers)
import           Codec.Picture              (DynamicImage (..), Image,
                                             PixelRGBA8, readImage, writePng)
-- import qualified Pixs.Filter                as F
-- import qualified Pixs.Information.Histogram as H
import qualified Pixs.Transformation        as T
import qualified Pixs.Arithmetic            as Arith
import           Prelude                    hiding (error, flip)
import qualified Options.Applicative        as A
import           Options.Applicative        (Parser, (<>))

data Command = Brightness FilePath   Int      FilePath
             | Red        FilePath   Int      FilePath
             | Green      FilePath   Int      FilePath
             | Blue       FilePath   Int      FilePath
             | Flip       FilePath   FilePath
             | Add        [FilePath] FilePath
             deriving (Eq, Read)

inputOption ∷ Parser FilePath
inputOption = A.strOption (   A.long "in"
                           <> A.metavar "INPUT"
                           <> A.help "Input image file to be transformed")

outputOption ∷ Parser FilePath
outputOption = A.strOption (   A.long "out"
                            <> A.metavar "OUTPUT"
                            <> A.help "File name to write to.")

magnitudeOption ∷ Parser Int
magnitudeOption = (A.option A.auto
                   (   A.long "magnitude"
                    <> A.short 'm'
                    <> A.metavar "MAGNITUDE"
                    <> A.help "Magnitude of change"))

brightness ∷ Parser Command
brightness = Brightness
    <$> inputOption
    <*> (A.option A.auto
           (   A.long "magnitude"
            <> A.short 'm'
            <> A.metavar "MAGNITUDE"
            <> A.help "Magnitude of brightness change"))
    <*> outputOption

red ∷ Parser Command
red =  Red
   <$> inputOption
   <*> magnitudeOption
   <*> outputOption

green ∷ Parser Command
green =  Green
     <$> inputOption
     <*> magnitudeOption
     <*> outputOption

blue ∷ Parser Command
blue =  Blue
    <$> inputOption
    <*> magnitudeOption
    <*> outputOption

flip ∷ Parser Command
flip = Flip <$> inputOption <*> outputOption

add ∷ Parser Command
add = Add
    <$> (A.many $ A.strOption
           (   A.long "img"
            <> A.metavar "IMAGE"
            <> A.help "Image to be added"))
    <*> outputOption

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
                     (A.progDesc "Add one or more images together."))
         <> A.command "red"
             (A.info red
                     (A.progDesc "Change the red component of a given image."))
         <> A.command "blue"
             (A.info blue
                     (A.progDesc "Change the blue component of a given image."))
         <> A.command "green"
              (A.info green
                      (A.progDesc "Change the green component of a given image."))

unwrapImage ∷ DynamicImage → Maybe (Image PixelRGBA8)
unwrapImage (ImageRGBA8 img) = Just img
unwrapImage _                = Nothing

run ∷ Command → IO ()
run (Brightness inFile n outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left error  → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                         $ T.changeBrightness n img
      _              → putStrLn "Type not handled yet."
run (Flip inFile outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left  error → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                         $ T.flip img
      _              → putStrLn "Type not handled yet."
run (Add imgPaths outFile) = do
  imgsLoad ← mapM readImage imgPaths
  case partitionEithers imgsLoad of
    ([], images@(_:_)) →
      case mapM unwrapImage images of
        Just imgs → writePng outFile $ foldl1 Arith.add imgs
        Nothing   → putStrLn "Type not handled yet."
    (errs, _)  → mapM_ putStrLn errs
run (Red inFile n outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left error → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                       $ T.changeRed n img
      _              → putStrLn "Type not handled yet."
run (Green inFile n outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left error → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                       $ T.changeGreen n img
      _              → putStrLn "Type not handled yet."
run (Blue inFile n outFile) = do
  imageLoad ← readImage inFile
  case imageLoad of
    Left error → putStrLn error
    Right image → case image of
      ImageRGBA8 img → writePng outFile
                       $ T.changeBlue n img
      _              → putStrLn "Type not handled yet."

main ∷ IO ()
main = let opts = A.info (A.helper <*> menu)
                  (   A.fullDesc
                   <> A.progDesc "Process images."
                   <> A.header "pixs")
       in A.execParser opts >>= run
