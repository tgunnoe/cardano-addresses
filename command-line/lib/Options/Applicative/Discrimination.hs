{-# LANGUAGE LambdaCase #-}

{-# OPTIONS_HADDOCK hide #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}

module Options.Applicative.Discrimination
    (
    -- * Type (re-export from Cardano.Address)
      NetworkTag(..)

    -- * Applicative Parser
    , networkTagOpt
    ) where

import Prelude

import Cardano.Address
    ( NetworkTag (..) )
import Data.List
    ( intercalate )
import Options.Applicative
    ( Parser
    , completer
    , eitherReader
    , helpDoc
    , listCompleter
    , long
    , metavar
    , option
    , (<|>)
    )
import Options.Applicative.Help.Pretty
    ( string, vsep )
import Options.Applicative.Style
    ( Style (..) )
import Text.Read
    ( readMaybe )

import qualified Cardano.Address.Style.Byron as Byron
import qualified Cardano.Address.Style.Jormungandr as Jormungandr
import qualified Cardano.Address.Style.Shelley as Shelley

--
-- Applicative Parser
--

-- | Parse a 'NetworkTag' from the command-line, as an option
networkTagOpt :: Style -> Parser NetworkTag
networkTagOpt style = option (eitherReader reader) $ mempty
    <> metavar "NETWORK-TAG"
    <> long "network-tag"
    <> helpDoc  (Just (vsep (string <$> doc style)))
    <> completer (listCompleter $ show <$> tagsFor style)
  where
    doc style' =
        [ "A tag which identifies a Cardano network."
        , ""
        , header
        ]
        ++ (fmtAllowedKeyword <$> ("" : allowedKeywords style'))
        ++
        [ ""
        , "...or alternatively, an explicit network tag as an integer."
        ]
      where
        header = case style' of
            Byron ->
                "┌ Byron / Icarus ──────────"
            Icarus ->
                "┌ Byron / Icarus ──────────"
            Jormungandr ->
                "┌ Jormungandr ─────────────"
            Shelley ->
                "┌ Shelley ─────────────────"
        fmtAllowedKeyword network =
            "│ " <> network

    tagsFor = \case
        Byron ->
            [ unNetworkTag (snd Byron.byronMainnet)
            , unNetworkTag (snd Byron.byronStaging)
            , unNetworkTag (snd Byron.byronTestnet)
            ]
        Icarus ->
            tagsFor Byron
        Jormungandr ->
            [ unNetworkTag Jormungandr.incentivizedTestnet
            ]
        Shelley ->
            [ unNetworkTag Shelley.shelleyMainnet
            , unNetworkTag Shelley.shelleyTestnet
            ]

    reader str = maybe (Left err) Right
        ((NetworkTag <$> readMaybe str) <|> (readKeywordMaybe str style))
      where
        err =
            "Invalid network tag. Must be an integer value or one of the \
            \allowed keywords: " <> intercalate ", " (allowedKeywords style)

    readKeywordMaybe str = \case
        Byron | str == "mainnet" -> pure (snd Byron.byronMainnet)
        Byron | str == "staging" -> pure (snd Byron.byronStaging)
        Byron | str == "testnet" -> pure (snd Byron.byronTestnet)
        Icarus -> readKeywordMaybe str Byron
        Shelley | str == "mainnet" -> pure Shelley.shelleyMainnet
        Shelley | str == "testnet" -> pure Shelley.shelleyTestnet
        Jormungandr | str == "testnet" -> pure Jormungandr.incentivizedTestnet
        _ -> Nothing

    allowedKeywords = \case
        Byron -> ["mainnet", "staging", "testnet"]
        Icarus -> allowedKeywords Byron
        Shelley -> ["mainnet", "testnet"]
        Jormungandr -> ["testnet"]