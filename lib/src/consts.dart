// ignore_for_file: public_member_api_docs

const tokenSpace = 0x20;
const tokenLineFeed = 0x0A;
const tokenCarriageReturn = 0x0D;
const tokenTab = 0x09;
const tokenBackspace = 0x08;
const tokenFormFeed = 0x0C;

const tokenDoubleQuote = 0x22;
const tokenSlash = 0x2F;
const tokenBackslash = 0x5C;
const tokenComma = 0x2C;
const tokenPeriod = 0x2E;
const tokenColon = 0x3A;
const tokenLBracket = 0x5B;
const tokenRBracket = 0x5D;
const tokenLBrace = 0x7B;
const tokenRBrace = 0x7D;

const tokenA = 0x61;
const tokenB = 0x62;
const tokenC = 0x63;
const tokenD = 0x64;
const tokenE = 0x65;
const tokenUpperE = 0x45;
const tokenF = 0x66;
const tokenL = 0x6C;
const tokenN = 0x6E;
const tokenR = 0x72;
const tokenS = 0x73;
const tokenT = 0x74;
const tokenU = 0x75;

const tokenZero = 0x30;
const tokenOne = 0x31;
const tokenTwo = 0x32;
const tokenThree = 0x33;
const tokenFour = 0x34;
const tokenFive = 0x35;
const tokenSix = 0x36;
const tokenSeven = 0x37;
const tokenEight = 0x38;
const tokenNine = 0x39;
const tokenPlus = 0x2B;
const tokenMinus = 0x2D;

const powersOfTen = [
  1.0, // 0
  10.0,
  100.0,
  1000.0,
  10000.0,
  100000.0, // 5
  1000000.0,
  10000000.0,
  100000000.0,
  1000000000.0,
  10000000000.0, // 10
  100000000000.0,
  1000000000000.0,
  10000000000000.0,
  100000000000000.0,
  1000000000000000.0, // 15
  10000000000000000.0,
  100000000000000000.0,
  1000000000000000000.0,
  10000000000000000000.0,
  100000000000000000000.0, // 20
  1000000000000000000000.0,
  10000000000000000000000.0,
];

const oneByteLimit = 0x7f; // 7 bits
const twoByteLimit = 0x7ff; // 11 bits
const surrogateTagMask = 0xFC00;
const surrogateValueMask = 0x3FF;
const leadSurrogateMin = 0xD800;

const maxInt = 9223372036854775807;

const canDirectWrite = [
  false, false, false, false, false, false, false, false, //
  false, false, false, false, false, false, false, false, //
  false, false, false, false, false, false, false, false, //
  false, false, false, false, false, false, false, false, //

  true, true, false /* " */, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //

  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, false /* \ */, true, true, true, //

  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
  true, true, true, true, true, true, true, true, //
];

const hexDigits = [
  tokenZero, tokenOne, tokenTwo, tokenThree, tokenFour, //
  tokenFive, tokenSix, tokenSeven, tokenEight, tokenNine, //
  tokenA, tokenB, tokenC, tokenD, tokenE, tokenF, //
];
