import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Single source of truth for all icons in Masarify.
/// NEVER use Icons.* directly in widgets — use AppIcons.* exclusively.
/// Uses Phosphor Icons for a clean, consistent visual style.
abstract final class AppIcons {
  // ── Navigation ────────────────────────────────────────────────────────
  static const IconData home = PhosphorIconsFill.house;
  static const IconData homeOutlined = PhosphorIconsRegular.house;
  static const IconData transactions = PhosphorIconsFill.receipt;
  static const IconData transactionsOutlined = PhosphorIconsRegular.receipt;
  static const IconData analytics = PhosphorIconsFill.chartBar;
  static const IconData analyticsOutlined = PhosphorIconsRegular.chartBar;
  static const IconData more = PhosphorIconsFill.squaresFour;
  static const IconData moreOutlined = PhosphorIconsRegular.squaresFour;
  static const IconData settings = PhosphorIconsFill.gear;
  static const IconData settingsOutlined = PhosphorIconsRegular.gear;

  // ── Actions ───────────────────────────────────────────────────────────
  static const IconData add = PhosphorIconsBold.plus;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter = PhosphorIconsRegular.funnelSimple;
  static const IconData mic = PhosphorIconsFill.microphone;
  static const IconData location = PhosphorIconsFill.mapPin;
  static const IconData close = PhosphorIconsBold.x;
  static const IconData lock = PhosphorIconsFill.lock;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData checkCircle = PhosphorIconsFill.checkCircle;
  static const IconData errorCircle = PhosphorIconsFill.warningCircle;
  static const IconData infoFilled = PhosphorIconsFill.info;
  static const IconData arrowBack = PhosphorIconsBold.caretLeft;
  static const IconData arrowForward = PhosphorIconsBold.caretRight;
  static const IconData backspace = PhosphorIconsRegular.backspace;
  static const IconData chevronRight = PhosphorIconsRegular.caretRight;
  static const IconData chevronLeft = PhosphorIconsRegular.caretLeft;
  static const IconData refresh = PhosphorIconsRegular.arrowsClockwise;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData share = PhosphorIconsRegular.shareFat;

  // ── Transaction types ─────────────────────────────────────────────────
  static const IconData expense = PhosphorIconsBold.arrowDown;
  static const IconData income = PhosphorIconsBold.arrowUp;
  static const IconData transfer = PhosphorIconsBold.arrowsLeftRight;

  // ── Finance ───────────────────────────────────────────────────────────
  static const IconData wallet = PhosphorIconsFill.wallet;
  static const IconData budget = PhosphorIconsFill.chartBar;
  static const IconData bill = PhosphorIconsFill.receipt;
  static const IconData recurring = PhosphorIconsFill.repeat;
  static const IconData recurringOutlined = PhosphorIconsRegular.repeat;
  static const IconData category = PhosphorIconsFill.gridFour;
  static const IconData calendar = PhosphorIconsRegular.calendarBlank;
  static const IconData sms = PhosphorIconsFill.chatText;
  static const IconData notification = PhosphorIconsFill.bell;
  static const IconData notificationOutlined = PhosphorIconsRegular.bell;
  static const IconData backup = PhosphorIconsFill.cloudArrowUp;
  static const IconData security = PhosphorIconsFill.shield;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData eyeOff = PhosphorIconsRegular.eyeSlash;
  static const IconData star = PhosphorIconsFill.star;
  static const IconData goals = PhosphorIconsFill.target;
  static const IconData reports = PhosphorIconsFill.lightbulb;
  static const IconData bank = PhosphorIconsFill.bank;
  static const IconData export_ = PhosphorIconsRegular.uploadSimple;
  static const IconData import_ = PhosphorIconsRegular.downloadSimple;
  static const IconData tag = PhosphorIconsFill.tag;
  static const IconData pin = PhosphorIconsFill.password;
  static const IconData fingerprint = PhosphorIconsRegular.fingerprint;
  static const IconData language = PhosphorIconsRegular.globe;
  static const IconData theme = PhosphorIconsFill.moon;
  static const IconData themeLight = PhosphorIconsFill.sun;
  static const IconData currency = PhosphorIconsBold.currencyDollar;
  static const IconData help = PhosphorIconsRegular.question;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData inbox = PhosphorIconsFill.tray;
  static const IconData expandMore = PhosphorIconsRegular.caretDown;
  static const IconData expandLess = PhosphorIconsRegular.caretUp;
  static const IconData creditCard = PhosphorIconsRegular.creditCard;

  // ── Account types ───────────────────────────────────────────────────
  static const IconData physicalCash = PhosphorIconsFill.coins;
  static const IconData prepaidCard = PhosphorIconsFill.creditCard;
  static const IconData investmentAccount = PhosphorIconsBold.trendUp;

  // ── Category icons (subset used in UI) ───────────────────────────────
  static const IconData food = PhosphorIconsFill.forkKnife;
  static const IconData transport = PhosphorIconsFill.car;
  static const IconData housing = PhosphorIconsFill.houseLine;
  static const IconData utilities = PhosphorIconsFill.lightning;
  static const IconData phone = PhosphorIconsFill.deviceMobile;
  static const IconData health = PhosphorIconsFill.firstAid;
  static const IconData groceries = PhosphorIconsFill.shoppingCart;
  static const IconData education = PhosphorIconsFill.graduationCap;
  static const IconData shopping = PhosphorIconsFill.shoppingBag;
  static const IconData entertainment = PhosphorIconsFill.filmSlate;
  static const IconData clothing = PhosphorIconsFill.tShirt;
  static const IconData personalCare = PhosphorIconsFill.flower;
  static const IconData gifts = PhosphorIconsFill.gift;
  static const IconData travel = PhosphorIconsFill.airplane;
  static const IconData subscriptions = PhosphorIconsFill.playCircle;
  static const IconData salary = PhosphorIconsFill.money;
  static const IconData freelance = PhosphorIconsFill.briefcase;
  static const IconData business = PhosphorIconsFill.storefront;
  static const IconData investment = PhosphorIconsBold.trendUp;
  static const IconData otherExpense = PhosphorIconsRegular.dotsThreeOutline;
  static const IconData otherIncome = PhosphorIconsRegular.dotsThreeOutline;
  static const IconData installments = PhosphorIconsFill.creditCard;
  static const IconData insurance = PhosphorIconsFill.shield;
  static const IconData fuel = PhosphorIconsFill.gasPump;
  static const IconData maintenance = PhosphorIconsFill.wrench;
  static const IconData kidsFamily = PhosphorIconsFill.baby;
  static const IconData pets = PhosphorIconsFill.pawPrint;
  static const IconData coffee = PhosphorIconsFill.coffee;
  static const IconData homeSupplies = PhosphorIconsFill.broom;
  static const IconData charity = PhosphorIconsFill.handHeart;
  static const IconData bankFees = PhosphorIconsFill.bank;
  static const IconData delivery = PhosphorIconsFill.truck;
  static const IconData savingsTransfer = PhosphorIconsFill.piggyBank;
  static const IconData ai = PhosphorIconsFill.sparkle;
  static const IconData send = PhosphorIconsFill.paperPlaneRight;
  static const IconData archive = PhosphorIconsRegular.archive;
  static const IconData unarchive = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData moreVert = PhosphorIconsRegular.dotsThreeVertical;
  static const IconData dragHandle = PhosphorIconsRegular.dotsSixVertical;
  static const IconData sliders = PhosphorIconsBold.sliders;

  // ── Trend indicators ───────────────────────────────────────────────────
  static const IconData trendingUp = PhosphorIconsBold.trendUp;
  static const IconData trendingDown = PhosphorIconsBold.trendDown;

  // ── Wallet type resolver ──────────────────────────────────────────────
  /// Maps a wallet type string to its icon. Single source of truth —
  /// replaces the 3 duplicate `_typeIcon()` methods that existed in
  /// AccountCarousel, WalletsScreen, and AddTransactionScreen.
  static IconData walletType(String type) => switch (type) {
        'physical_cash' => physicalCash,
        'bank' => bank,
        'mobile_wallet' => phone,
        'credit_card' => creditCard,
        'prepaid_card' => prepaidCard,
        'investment' => investmentAccount,
        _ => wallet,
      };
}
