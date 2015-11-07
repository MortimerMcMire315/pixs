module Transformations where

import Control.Applicative
import Data.Word (Word8(..))
import Codec.Picture(PixelRGBA8(..), Image(..), Pixel, pixelMap
                    ,imageHeight, imageWidth, pixelAt, generateImage)

adjustBy :: Word8 -> Int -> Word8
adjustBy x amount
  | newVal > 255 = 255
  -- | newVal < 0   = fromIntegral 0
  | otherwise    = newVal
  where newVal   = fromIntegral (x + fromIntegral amount)

changeBrightness :: Int -> Image PixelRGBA8 -> Image PixelRGBA8
changeBrightness amount = pixelMap changeBrightness'
  where changeBrightness' (PixelRGBA8 r g b a) = PixelRGBA8 r' g' b' a
          where r' = r `adjustBy` amount
                g' = g `adjustBy` amount
                b' = b `adjustBy` amount

changeRed :: Int -> Image PixelRGBA8 -> Image PixelRGBA8
changeRed amount = pixelMap changeRed'
  where changeRed' (PixelRGBA8 r g b a) = PixelRGBA8 (r `adjustBy` amount) g b a

changeGreen :: Int -> Image PixelRGBA8 -> Image PixelRGBA8
changeGreen amount = pixelMap changeGreen'
  where changeGreen' (PixelRGBA8 r g b a) = PixelRGBA8 r g' b a
                                            where g' = g `adjustBy` amount

flipVertical :: Pixel a => Image a -> Image a
flipVertical img =  generateImage complement (imageWidth img) (imageHeight img)
  where complement x y = pixelAt img x ((imageHeight img) - y - 1)

flipHorizontal :: Pixel a => Image a -> Image a
flipHorizontal img = generateImage complement (imageWidth img) (imageHeight img)
  where complement x y = pixelAt img (imageWidth img - x - 1) y

flip :: Pixel a => Image a -> Image a
flip = flipVertical . flipHorizontal

blur :: Image PixelRGBA8 -> Image PixelRGBA8
blur img = generateImage blurPixelAt (imageWidth img) (imageHeight img)
  where blurPixelAt :: Int -> Int -> PixelRGBA8
        blurPixelAt x y = 0.125 `scale` pixel'
          where pixel' = (foldr add black [ (4.0 `scale` (pixelAt' img x y))
                                          , (pixelAt' img (x-1) y)
                                          , (pixelAt' img (x+1) y)
                                          , (pixelAt' img x (y-1))])
        black = PixelRGBA8 0 0 0 0
        scale :: Rational -> PixelRGBA8 -> PixelRGBA8
        scale x (PixelRGBA8 r g b a) = PixelRGBA8 r' g' b' a
          where (r':g':b':[]) = map (fromIntegral . truncate . (x *) . toRational) [r, g, b]

        -- TODO: Since pixel components are of type Word8, they might be
        -- wrapping around when two colors are added to each other. A
        -- possible fix is to modify adjustBy so that it can be used to fix
        -- and then using it.
        add (PixelRGBA8 r1 g1 b1 _) (PixelRGBA8 r2 g2 b2 _) = newPixel
          where newPixel = PixelRGBA8 (r1 + r2)
                                      (g1 + g2)
                                      (b1 + b2)
                                      255

        pixelAt' img x y
          | (x < 0) || (y < 0) ||
            (x >= (imageWidth img)) ||
            (y >= (imageHeight img)) = pixelAt img 0 0
          | otherwise = pixelAt img x y
