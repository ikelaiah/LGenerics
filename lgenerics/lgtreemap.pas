{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Generic sorted map implementations on top of AVL tree.                  *
*                                                                           *
*   Copyright(c) 2018-2025 A.Koverdyaev(avk)                                *
*                                                                           *
*   This code is free software; you can redistribute it and/or modify it    *
*   under the terms of the Apache License, Version 2.0;                     *
*   You may obtain a copy of the License at                                 *
*     http://www.apache.org/licenses/LICENSE-2.0.                           *
*                                                                           *
*  Unless required by applicable law or agreed to in writing, software      *
*  distributed under the License is distributed on an "AS IS" BASIS,        *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
*  See the License for the specific language governing permissions and      *
*  limitations under the License.                                           *
*                                                                           *
*****************************************************************************}
unit lgTreeMap;

{$mode objfpc}{$H+}
{$INLINE ON}
{$MODESWITCH NESTEDPROCVARS}
{$MODESWITCH ADVANCEDRECORDS}

interface

uses

  SysUtils,
  lgUtils,
  {%H-}lgHelpers,
  lgAbstractContainer,
  lgAvlTree,
  lgStrConst;

type

  { TGAbstractTreeMap:  common tree map abstract ancestor class }
  generic TGAbstractTreeMap<TKey, TValue> = class abstract(specialize TGAbstractMap<TKey, TValue>)
  public
  type
    TAbstractTreeMap = specialize TGAbstractTreeMap<TKey, TValue>;

  protected
  type
    TTree = specialize TGCustomAvlTree<TKey, TEntry>;
    PNode = TTree.PNode;

    TKeyEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TKey; override;
    public
      constructor Create(aMap: TAbstractTreeMap; aReverse: Boolean = False);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TValueEnumerable = class(TCustomValueEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TValue; override;
    public
      constructor Create(aMap: TAbstractTreeMap; aReverse: Boolean = False);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TEntryEnumerable = class(TCustomEntryEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TEntry; override;
    public
      constructor Create(aMap: TAbstractTreeMap; aReverse: Boolean = False);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TKeyTailEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TKey; override;
    public
      constructor Create(const aLowBound: TKey; aMap: TAbstractTreeMap; aInclusive: Boolean);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

  var
    FTree: TTree;
    function  GetCount: SizeInt; override;
    function  GetCapacity: SizeInt; override;
    function  Find(const aKey: TKey): PEntry; override;
    //return True if aKey found, otherwise insert (garbage) pair and return False;
    function  FindOrAdd(const aKey: TKey; out p: PEntry): Boolean; override;
    function  DoExtract(const aKey: TKey; out v: TValue): Boolean; override;
    function  DoRemoveIf(aTest: TEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestEntryTest): SizeInt; override;
    function  DoExtractIf(aTest: TEntryTest): TEntryArray; override;
    function  DoExtractIf(aTest: TOnEntryTest): TEntryArray; override;
    function  DoExtractIf(aTest: TNestEntryTest): TEntryArray; override;
    procedure DoClear; override;
    procedure DoEnsureCapacity(aValue: SizeInt); override;
    procedure DoTrimToFit; override;
    function  GetKeys: IKeyEnumerable; override;
    function  GetValues: IValueEnumerable; override;
    function  GetEntries: IEntryEnumerable; override;
    function  FindNearestLT(const aPattern: TKey; out aKey: TKey): Boolean;
    function  FindNearestLE(const aPattern: TKey; out aKey: TKey): Boolean;
    function  FindNearestGT(const aPattern: TKey; out aKey: TKey): Boolean;
    function  FindNearestGE(const aPattern: TKey; out aKey: TKey): Boolean;
  public
    destructor Destroy; override;
    function ReverseKeys: IKeyEnumerable;
    function ReverseValues: IValueEnumerable;
    function ReverseEntries: IEntryEnumerable;
    function FindFirstKey(out aKey: TKey): Boolean;
    function FirstKey: TKeyOptional;
    function FindLastKey(out aKey: TKey): Boolean;
    function LastKey: TKeyOptional;
    function FindFirstValue(out aValue: TValue): Boolean;
    function FirstValue: TValueOptional;
    function FindLastValue(out aValue: TValue): Boolean;
    function LastValue: TValueOptional;
    function FindMin(out aKey: TKey): Boolean; inline;
    function Min: TKeyOptional; inline;
    function FindMax(out aKey: TKey): Boolean; inline;
    function Max: TKeyOptional; inline;
  { returns True if exists key whose value greater then or equal to aKey (depending on aInclusive) }
    function FindCeil(const aKey: TKey; out aCeil: TKey; aInclusive: Boolean = True): Boolean;
  { returns True if exists key whose value less then aKey (or equal to aKey, depending on aInclusive) }
    function FindFloor(const aKey: TKey; out aFloor: TKey; aInclusive: Boolean = False): Boolean;
  { enumerates keys which are strictly less than(if not aInclusive) aHighBound }
    function Head(const aHighBound: TKey; aInclusive: Boolean = False): IKeyEnumerable; virtual; abstract;
  { enumerates keys whose are greater than or equal to aLowBound(if aInclusive) }
    function Tail(const aLowBound: TKey; aInclusive: Boolean = True): IKeyEnumerable;
  { enumerates keys which are greater than or equal to aLowBound and strictly less than aHighBound(by default) }
    function Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): IKeyEnumerable;
      virtual; abstract;
  { returns sorted map whose keys are strictly less than(if not aInclusive) aHighBound }
    function HeadMap(const aHighBound: TKey; aInclusive: Boolean = False): TAbstractTreeMap; virtual; abstract;
  { returns sorted map whose keys are greater than or equal to(if aInclusive) aLowBound }
    function TailMap(const aLowBound: TKey; aInclusive: Boolean = True): TAbstractTreeMap; virtual; abstract;
  { returns sorted map whose keys are greater than or equal to aLowBound and strictly less than
    aHighBound(by default) }
    function SubMap(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TAbstractTreeMap;
      virtual; abstract;
  end;


  { TGBaseTreeMap implements sorted map;
     functor TKeyCmpRel (key comparison relation) must provide:
       class function Less([const[ref]] L, R: TKey): Boolean;  }
  generic TGBaseTreeMap<TKey, TValue, TKeyCmpRel> = class(specialize TGAbstractTreeMap<TKey, TValue>)
  protected
  type
    TBaseTree  = specialize TGAvlTree<TKey, TEntry, TKeyCmpRel>;

    TKeyHeadEnumerable = class(TCustomKeyEnumerable)
    private
      FEnum: TTree.TEnumerator;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
    protected
      function  GetCurrent: TKey; override;
    public
      constructor Create(const aHighBound: TKey; aMap: TAbstractTreeMap; aInclusive: Boolean); overload;
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TKeyRangeEnumerable = class(TKeyHeadEnumerable)
      constructor Create(const aLowBound, aHighBound: TKey; aMap: TAbstractTreeMap; aBounds: TRangeBounds); overload;
    end;

    class function DoCompare(const L, R: TKey): Boolean; static;
  public
  type
    TComparator = specialize TGLessCompare<TKey>;
    class function Comparator: TComparator; static; inline;
    constructor Create;
    constructor Create(aCapacity: SizeInt);
    constructor Create(const a: array of TEntry);
    constructor Create(e: IEntryEnumerable);
    constructor CreateCopy(aMap: TGBaseTreeMap);
    function Clone: TGBaseTreeMap; override;
    function Head(const aHighBound: TKey; aInclusive: Boolean = False): IKeyEnumerable; override;
    function Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): IKeyEnumerable;
      override;
    function HeadMap(const aHighBound: TKey; aInclusive: Boolean = False): TGBaseTreeMap; override;
    function TailMap(const aLowBound: TKey; aInclusive: Boolean = True): TGBaseTreeMap; override;
    function SubMap(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TGBaseTreeMap;
      override;
  end;

  { TGTreeMap implements sorted map; it assumes that type TKey implements TKeyCmpRel}
  generic TGTreeMap<TKey, TValue> = class(specialize TGBaseTreeMap<TKey, TValue, TKey>);

  { TGObjectTreeMap: an attempt to set ownership of keys or values will raise an exception
    if the corresponding type is not a class type }
  generic TGObjectTreeMap<TKey, TValue, TKeyCmpRel> = class(specialize TGBaseTreeMap<TKey, TValue, TKeyCmpRel>)
  protected
    FOwnsKeys: Boolean;
    FOwnsValues: Boolean;
    procedure SetOwnsKeys(aValue: Boolean);
    procedure SetOwnsValues(aValue: Boolean);
    procedure EntryRemoving(p: PEntry);
    procedure SetOwnership(aOwns: TMapObjOwnership);
    function  DoRemove(const aKey: TKey): Boolean; override;
    function  DoRemoveIf(aTest: TEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestEntryTest): SizeInt; override;
    procedure DoClear; override;
    function  DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean; override;
    function  DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean; override;
  public
    constructor Create(aOwns: TMapObjOwnership = []);
    constructor Create(aCapacity: SizeInt; aOwns: TMapObjOwnership);
    constructor Create(const a: array of TEntry; aOwns: TMapObjOwnership);
    constructor Create(e: IEntryEnumerable; aOwns: TMapObjOwnership);
    constructor CreateCopy(aMap: TGObjectTreeMap);
    function Clone: TGObjectTreeMap; override;
    property OwnsKeys: Boolean read FOwnsKeys write SetOwnsKeys;
    property OwnsValues: Boolean read FOwnsValues write SetOwnsValues;
  end;

  generic TGObjTreeMap<TKey, TValue> = class(specialize TGObjectTreeMap<TKey, TValue, TKey>);

  { TGComparableTreeMap implements sorted map; it assumes that type T has defined comparison operator < }
  generic TGComparableTreeMap<TKey, TValue> = class(specialize TGAbstractTreeMap<TKey, TValue>)
  protected
  type
    TComparableTree = specialize TGComparableAvlTree<TKey, TEntry>;

    TKeyHeadEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
      function  GetCurrent: TKey; override;
    public
      constructor Create(const aHighBound: TKey; aMap: TAbstractTreeMap; aInclusive: Boolean); overload;
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TKeyRangeEnumerable = class(TKeyHeadEnumerable)
      constructor Create(const aLowBound, aHighBound: TKey; aMap: TAbstractTreeMap; aBounds: TRangeBounds); overload;
    end;

    class function DoCompare(const L, R: TKey): Boolean; static;
  public
  type
    TComparator = specialize TGLessCompare<TKey>;
    class function Comparator: TComparator; static; inline;
    constructor Create;
    constructor Create(aCapacity: SizeInt);
    constructor Create(const a: array of TEntry);
    constructor Create(e: IEntryEnumerable);
    constructor CreateCopy(aMap: TGComparableTreeMap);
    function Clone: TGComparableTreeMap; override;
    function Head(const aHighBound: TKey; aInclusive: Boolean = False): IKeyEnumerable; override;
    function Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): IKeyEnumerable; override;
    function HeadMap(const aHighBound: TKey; aInclusive: Boolean = False): TGComparableTreeMap; override;
    function TailMap(const aLowBound: TKey; aInclusive: Boolean = True): TGComparableTreeMap; override;
    function SubMap(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TGComparableTreeMap; override;
  end;

  { TGRegularTreeMap implements sorted map with regular comparator }
  generic TGRegularTreeMap<TKey, TValue> = class(specialize TGAbstractTreeMap<TKey, TValue>)
  public
  type
    TLess = specialize TGLessCompare<TKey>;

  protected
  type
    TRegularTree  = specialize TGRegularAvlTree<TKey, TEntry>;

    TKeyHeadEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      FLess: TLess;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
      function  GetCurrent: TKey; override;
    public
      constructor Create(const aHighBound: TKey; aMap: TAbstractTreeMap; aInclusive: Boolean); overload;
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TKeyRangeEnumerable = class(TKeyHeadEnumerable)
      constructor Create(const aLowBound, aHighBound: TKey; aMap: TAbstractTreeMap; aBounds: TRangeBounds); overload;
    end;

  public
    constructor Create;
    constructor Create(aLess: TLess);
    constructor Create(aCapacity: SizeInt; aLess: TLess);
    constructor Create(const a: array of TEntry; aLess: TLess);
    constructor Create(e: IEntryEnumerable; aLess: TLess);
    constructor CreateCopy(aMap: TGRegularTreeMap);
    function Comparator: TLess; inline;
    function Clone: TGRegularTreeMap; override;
    function Head(const aHighBound: TKey; aInclusive: Boolean = False): IKeyEnumerable; override;
    function Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): IKeyEnumerable; override;
    function HeadMap(const aHighBound: TKey; aInclusive: Boolean = False): TGRegularTreeMap; override;
    function TailMap(const aLowBound: TKey; aInclusive: Boolean = True): TGRegularTreeMap; override;
    function SubMap(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TGRegularTreeMap; override;
  end;

  { TGObjectRegularTreeMap: an attempt to set ownership of keys or values will raise an exception
    if the corresponding type is not a class type }
  generic TGObjectRegularTreeMap<TKey, TValue> = class(specialize TGRegularTreeMap<TKey, TValue>)
  protected
    FOwnsKeys: Boolean;
    FOwnsValues: Boolean;
    procedure SetOwnsKeys(aValue: Boolean);
    procedure SetOwnsValues(aValue: Boolean);
    procedure EntryRemoving(p: PEntry);
    procedure SetOwnership(aOwns: TMapObjOwnership);
    function  DoRemove(const aKey: TKey): Boolean; override;
    function  DoRemoveIf(aTest: TEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestEntryTest): SizeInt; override;
    procedure DoClear; override;
    function  DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean; override;
    function  DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean; override;
  public
    constructor Create(aOwns: TMapObjOwnership = []);
    constructor Create(c: TLess; aOwns: TMapObjOwnership);
    constructor Create(aCapacity: SizeInt; c: TLess; aOwns: TMapObjOwnership);
    constructor Create(const a: array of TEntry; c: TLess; aOwns: TMapObjOwnership);
    constructor Create(e: IEntryEnumerable; c: TLess; aOwns: TMapObjOwnership);
    constructor CreateCopy(aMap: TGObjectRegularTreeMap);
    function Clone: TGObjectRegularTreeMap; override;
    property OwnsKeys: Boolean read FOwnsKeys write SetOwnsKeys;
    property OwnsValues: Boolean read FOwnsValues write SetOwnsValues;
  end;

  { TGDelegatedTreeMap implements sorted map with delegated comparator }
  generic TGDelegatedTreeMap<TKey, TValue> = class(specialize TGAbstractTreeMap<TKey, TValue>)
  public
  type
    TOnLess = specialize TGOnLessCompare<TKey>;

  protected
  type
    TDelegatedTree  = specialize TGDelegatedAvlTree<TKey, TEntry>;

    TKeyHeadEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: TTree.TEnumerator;
      FLess: TOnLess;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
      function  GetCurrent: TKey; override;
    public
      constructor Create(const aHighBound: TKey; aMap: TAbstractTreeMap; aInclusive: Boolean); overload;
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TKeyRangeEnumerable = class(TKeyHeadEnumerable)
      constructor Create(const aLowBound, aHighBound: TKey; aMap: TAbstractTreeMap; aBounds: TRangeBounds); overload;
    end;

  public
    constructor Create;
    constructor Create(aLess: TOnLess);
    constructor Create(aCapacity: SizeInt; aLess: TOnLess);
    constructor Create(const a: array of TEntry; aLess: TOnLess);
    constructor Create(e: IEntryEnumerable; aLess: TOnLess);
    constructor CreateCopy(aMap: TGDelegatedTreeMap);
    function Comparator: TOnLess;
    function Clone: TGDelegatedTreeMap; override;

    function Head(const aHighBound: TKey; aInclusive: Boolean = False): IKeyEnumerable; override;
    function Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): IKeyEnumerable;
      override;
    function HeadMap(const aHighBound: TKey; aInclusive: Boolean = False): TGDelegatedTreeMap; override;
    function TailMap(const aLowBound: TKey; aInclusive: Boolean = True): TGDelegatedTreeMap; override;
    function SubMap(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TGDelegatedTreeMap;
      override;
  end;

  { TGObjectDelegatedTreeMap: an attempt to set ownership of keys or values will raise an exception
    if the corresponding type is not a class type }
  generic TGObjectDelegatedTreeMap<TKey, TValue> = class(specialize TGDelegatedTreeMap<TKey, TValue>)
  protected
    FOwnsKeys: Boolean;
    FOwnsValues: Boolean;
    procedure SetOwnsKeys(aValue: Boolean);
    procedure SetOwnsValues(aValue: Boolean);
    procedure EntryRemoving(p: PEntry);
    procedure SetOwnership(aOwns: TMapObjOwnership);
    function  DoRemove(const aKey: TKey): Boolean; override;
    function  DoRemoveIf(aTest: TEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnEntryTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestEntryTest): SizeInt; override;
    procedure DoClear; override;
    function  DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean; override;
    function  DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean; override;
  public
    constructor Create(aOwns: TMapObjOwnership = []);
    constructor Create(c: TOnLess; aOwns: TMapObjOwnership);
    constructor Create(aCapacity: SizeInt; c: TOnLess; aOwns: TMapObjOwnership);
    constructor Create(const a: array of TEntry; c: TOnLess; aOwns: TMapObjOwnership);
    constructor Create(e: IEntryEnumerable; c: TOnLess; aOwns: TMapObjOwnership);
    constructor CreateCopy(aMap: TGObjectDelegatedTreeMap);
    function  Clone: TGObjectDelegatedTreeMap; override;
    property  OwnsKeys: Boolean read FOwnsKeys write SetOwnsKeys;
    property  OwnsValues: Boolean read FOwnsValues write SetOwnsValues;
  end;

  { TGLiteTreeMap implements sorted map; it mimics a value type,
    when assigned or passed by value, the entire map is copied;
      functor TKeyCmpRel (key comparision relation) must provide:
        class function Less([const[ref]] L, R: TKey): Boolean; }
  generic TGLiteTreeMap<TKey, TValue, TKeyCmpRel> = record
  public
  type
    PValue           = ^TValue;
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    PEntry           = ^TEntry;
    TEntryArray      = array of TEntry;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    TEntryTest       = specialize TGTest<TEntry>;
    TOnEntryTest     = specialize TGOnTest<TEntry>;
    TNestEntryTest   = specialize TGNestTest<TEntry>;
    IKeyCollection   = specialize IGCollection<TKey>;

  private
  type
    TTree = specialize TGLiteAvlTree<TKey, TEntry, TKeyCmpRel>;
    PTree = ^TTree;

  public
  type
    TEntryEnumerator = record
    private
      FTree: PTree;
      FCurrNode: SizeInt;
      FInCycle: Boolean;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap; aNode: SizeInt); inline;
    public
      function  MoveNext: Boolean; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TReverseEntries = record
    private
      FTree: PTree;
      FCurrNode: SizeInt;
      FInCycle: Boolean;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TReverseEntries; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TUnordEntries = record
    private
      FEnum: TTree.TUnordEnumerator;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TUnordEntries; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TKeys = record
    private
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TKey; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TKeys; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TKey read GetCurrent;
    end;

    TUnordKeys = record
    private
      FEnum: TTree.TUnordEnumerator;
      function  GetCurrent: TKey; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TUnordKeys; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TKey read GetCurrent;
    end;

    TValues = record
    private
      FEnum: TTree.TEnumerator;
      function  GetCurrent: TValue; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TValues; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TValue read GetCurrent;
    end;

    TUnordValues = record
    private
      FEnum: TTree.TUnordEnumerator;
      function  GetCurrent: TValue; inline;
      procedure Init(const aMap: TGLiteTreeMap); inline;
    public
      function  GetEnumerator: TUnordValues; inline;
      function  MoveNext: Boolean; inline;
      property  Current: TValue read GetCurrent;
    end;

    THead = record
    private
      FTree: PTree;
      FCurrNode: SizeInt;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap; const aBound: TKey; aInclusive: Boolean);
    public
      function  GetEnumerator: THead; inline;
      function  MoveNext: Boolean;
      property  Current: TEntry read GetCurrent;
    end;

    TTail = record
    private
      FTree: PTree;
      FCurrNode,
      FFirstNode: SizeInt;
      FInCycle: Boolean;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap; const aBound: TKey; aInclusive: Boolean);
    public
      function  GetEnumerator: TTail; inline;
      function  MoveNext: Boolean;
      property  Current: TEntry read GetCurrent;
    end;

    TRange = record
    private
      FTree: PTree;
      FCurrNode,
      FFirstNode: SizeInt;
      FHighBound: TKey;
      FInclusive,
      FDone: Boolean;
      function  GetCurrent: TEntry; inline;
      procedure Init(const aMap: TGLiteTreeMap; const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds);
    public
      function  GetEnumerator: TRange; inline;
      function  MoveNext: Boolean;
      property  Current: TEntry read GetCurrent;
    end;

  private
  var
    FTree: TTree;
    function  GetCount: SizeInt; inline;
    function  GetCapacity: SizeInt; inline;
    function  GetHeight: SizeInt; inline;
    function  GetConsistent: Boolean; inline;
    function  GetValue(const aKey: TKey): TValue;
    function  FindNearestLT(const aKey: TKey; out k: TKey): Boolean;
    function  FindNearestLE(const aKey: TKey; out k: TKey): Boolean;
    function  FindNearestGT(const aKey: TKey; out k: TKey): Boolean;
    function  FindNearestGE(const aKey: TKey; out k: TKey): Boolean;
  public
    function  GetEnumerator: TEntryEnumerator;
    function  ReverseEntries: TReverseEntries;
    function  UnOrdered: TUnordEntries; inline;
    function  Keys: TKeys; inline;
    function  UnordKeys: TUnordKeys; inline;
    function  Values: TValues; inline;
    function  UnordValues: TUnordValues; inline;
    function  ToArray: TEntryArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear; inline;
    procedure MakeEmpty; inline;
    procedure EnsureCapacity(aValue: SizeInt);
    procedure TrimToFit;
  { returns True and value mapped to aKey in the aValue parameter if instance
    contains aKey, False otherwise }
    function  TryGetValue(const aKey: TKey; out aValue: TValue): Boolean;
  { returns True and a pointer to the value mapped to aKey in the p parameter
    if instance contains aKey, False otherwise }
    function  TryGetMutValue(const aKey: TKey; out p: PValue): Boolean;
  { returns value mapped to aKey if instance contains aKey, otherwise returns aDefault }
    function  GetValueDef(const aKey: TKey; const aDefault: TValue): TValue;
  { returns a pointer to the value mapped to aKey; if instance does not contain such a key,
    it will be added with the value aDefault }
    function  GetMutValueDef(const aKey: TKey; const aDefault: TValue): PValue;
  { returns True if instance contains aKey, otherwise adds aKey and returns False;
    returns a pointer to value in the p parameter }
    function  FindOrAddMutValue(const aKey: TKey; out p: PValue): Boolean;
  { returns True and adds TEntry(aKey, aValue) only if instance does not contain aKey }
    function  Add(const aKey: TKey; const aValue: TValue): Boolean;
  { returns True and adds e only if instance does not contain e.Key }
    function  Add(const e: TEntry): Boolean; inline;
    procedure AddOrSetValue(const aKey: TKey; const aValue: TValue);
  { returns True if e.Key added, False otherwise }
    function  AddOrSetValue(const e: TEntry): Boolean;
  { adds only those entries whose keys are not present in the instance;
    returns the number of entries added }
    function  AddAll(const a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
    function  AddAll(constref aMap: TGLiteTreeMap): SizeInt;
  { returns True and maps aNewValue to aKey only if instance contains aKey,
    otherwise returns False }
    function  Replace(const aKey: TKey; const aNewValue: TValue): Boolean;
    function  Contains(const aKey: TKey): Boolean; inline;
    function  NonContains(const aKey: TKey): Boolean; inline;
    function  ContainsAny(const a: array of TKey): Boolean;
    function  ContainsAny(e: IKeyEnumerable): Boolean;
    function  ContainsAny(constref aMap: TGLiteTreeMap): Boolean;
    function  ContainsAll(const a: array of TKey): Boolean;
    function  ContainsAll(e: IKeyEnumerable): Boolean;
    function  ContainsAll(constref aMap: TGLiteTreeMap): Boolean;
  { returns True and removes the appropriate entry if instance contains the specified key,
    otherwise returns False }
    function  Remove(const aKey: TKey): Boolean; inline;
    function  RemoveAll(const a: array of TKey): SizeInt;
    function  RemoveAll(e: IKeyEnumerable): SizeInt;
    function  RemoveAll(constref aMap: TGLiteTreeMap): SizeInt;
    function  RemoveIf(aTest: TEntryTest): SizeInt;
    function  RemoveIf(aTest: TOnEntryTest): SizeInt;
    function  RemoveIf(aTest: TNestEntryTest): SizeInt;
    function  Extract(const aKey: TKey; out v: TValue): Boolean;
    function  ExtractIf(aTest: TEntryTest): TEntryArray;
    function  ExtractIf(aTest: TOnEntryTest): TEntryArray;
    function  ExtractIf(aTest: TNestEntryTest): TEntryArray;
    procedure RetainAll(aCollection: IKeyCollection);
    function  FindMinKey(out aKey: TKey): Boolean;
    function  FindMaxKey(out aKey: TKey): Boolean;
  { if the instance contains key that is greater than aKey(greater than or equal to aKey if aInclusive),
    returns True and the found key in aCeil parameter, otherwise returns False }
    function  FindCeilKey(const aKey: TKey; out aCeil: TKey; aInclusive: Boolean = True): Boolean;
  { if the instance contains key that is less than aKey(less than or equal to aKey if aInclusive),
    returns True and the found key in aFloor parameter, otherwise returns False }
    function  FindFloorKey(const aKey: TKey; out aFloor: TKey; aInclusive: Boolean = False): Boolean;
  { enumerates entries whose keys are less than aHighBound(less than or equal to aHighBound if aInclusive) }
    function  Head(const aHighBound: TKey; aInclusive: Boolean = False): THead; inline;
  { enumerates entries whose keys are greater than aLowBound(greater than or equal to aLowBound if aInclusive) }
    function  Tail(const aLowBound: TKey; aInclusive: Boolean = True): TTail; inline;
  { enumerates entries whose keys are greater than aLowBound (greater than or equal to aLowBound if rbLow in aIncludeBounds)
    and whose keys are less than aHighBound(less than or equal to aHighBound if rbHigh in TRangeBounds) }
    function  Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds = [rbLow]): TRange; inline;
    property  Count: SizeInt read GetCount;
    property  Capacity: SizeInt read GetCapacity;
    property  Height: SizeInt read GetHeight;
    property  Consistent: Boolean read GetConsistent;
  { GetValue will raise ELGMapError if aKey is not present in the instance }
    property  Items[const aKey: TKey]: TValue read GetValue write AddOrSetValue; default;
  end;

implementation
{$B-}{$COPERATORS ON}

{ TGAbstractTreeMap.TKeyEnumerable }

function TGAbstractTreeMap.TKeyEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGAbstractTreeMap.TKeyEnumerable.Create(aMap: TAbstractTreeMap; aReverse: Boolean);
begin
  inherited Create(aMap);
  if aReverse then
    FEnum := aMap.FTree.GetReverseEnumerator
  else
    FEnum := aMap.FTree.GetEnumerator;
end;

destructor TGAbstractTreeMap.TKeyEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractTreeMap.TKeyEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractTreeMap.TKeyEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractTreeMap.TValueEnumerable }

function TGAbstractTreeMap.TValueEnumerable.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Data.Value;
end;

constructor TGAbstractTreeMap.TValueEnumerable.Create(aMap: TAbstractTreeMap; aReverse: Boolean);
begin
  inherited Create(aMap);
  if aReverse then
    FEnum := aMap.FTree.GetReverseEnumerator
  else
    FEnum := aMap.FTree.GetEnumerator;
end;

destructor TGAbstractTreeMap.TValueEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractTreeMap.TValueEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractTreeMap.TValueEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGBaseTreeMap.TEntryEnumerable }

function TGAbstractTreeMap.TEntryEnumerable.GetCurrent: TEntry;
begin
  Result := FEnum.Current^.Data;
end;

constructor TGAbstractTreeMap.TEntryEnumerable.Create(aMap: TAbstractTreeMap; aReverse: Boolean);
begin
  inherited Create(aMap);
  if aReverse then
    FEnum := aMap.FTree.GetReverseEnumerator
  else
    FEnum := aMap.FTree.GetEnumerator;
end;

destructor TGAbstractTreeMap.TEntryEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractTreeMap.TEntryEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractTreeMap.TEntryEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractTreeMap.TKeyTailEnumerable }

function TGAbstractTreeMap.TKeyTailEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGAbstractTreeMap.TKeyTailEnumerable.Create(const aLowBound: TKey; aMap: TAbstractTreeMap;
  aInclusive: Boolean);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumeratorAt(aLowBound, aInclusive);
end;

destructor TGAbstractTreeMap.TKeyTailEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractTreeMap.TKeyTailEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractTreeMap.TKeyTailEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractTreeMap }

function TGAbstractTreeMap.GetCount: SizeInt;
begin
  Result := FTree.Count;
end;

function TGAbstractTreeMap.GetCapacity: SizeInt;
begin
  Result := FTree.Capacity;
end;

function TGAbstractTreeMap.Find(const aKey: TKey): PEntry;
var
  Node: PNode;
begin
  Node := FTree.Find(aKey);
  if Node <> nil then
    Result := @Node^.Data
  else
    Result := nil;
end;

function TGAbstractTreeMap.FindOrAdd(const aKey: TKey; out p: PEntry): Boolean;
var
  Node: PNode;
begin
  Result := FTree.FindOrAdd(aKey, Node);
  p := @Node^.Data;
end;

function TGAbstractTreeMap.DoExtract(const aKey: TKey; out v: TValue): Boolean;
var
  Node: PNode;
begin
  Node := FTree.Find(aKey);
  Result := Node <> nil;
  if Result then
    begin
      v := Node^.Data.Value;
      FTree.RemoveNode(Node);
    end;
end;

function TGAbstractTreeMap.DoRemoveIf(aTest: TEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest);
end;

function TGAbstractTreeMap.DoRemoveIf(aTest: TOnEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest);
end;

function TGAbstractTreeMap.DoRemoveIf(aTest: TNestEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest);
end;

function TGAbstractTreeMap.DoExtractIf(aTest: TEntryTest): TEntryArray;
var
  e: TExtractHelper;
begin
  e.Init;
  FTree.RemoveIfe(aTest, @e.OnExtract);
  Result := e.Final;
end;

function TGAbstractTreeMap.DoExtractIf(aTest: TOnEntryTest): TEntryArray;
var
  e: TExtractHelper;
begin
  e.Init;
  FTree.RemoveIfe(aTest, @e.OnExtract);
  Result := e.Final;
end;

function TGAbstractTreeMap.DoExtractIf(aTest: TNestEntryTest): TEntryArray;
var
  e: TExtractHelper;
begin
  e.Init;
  FTree.RemoveIfe(aTest, @e.OnExtract);
  Result := e.Final;
end;

procedure TGAbstractTreeMap.DoClear;
begin
  FTree.Clear;
end;

procedure TGAbstractTreeMap.DoEnsureCapacity(aValue: SizeInt);
begin
  FTree.EnsureCapacity(aValue);
end;

procedure TGAbstractTreeMap.DoTrimToFit;
begin
  FTree.TrimToFit;
end;

function TGAbstractTreeMap.GetKeys: IKeyEnumerable;
begin
  Result := TKeyEnumerable.Create(Self);
end;

function TGAbstractTreeMap.GetValues: IValueEnumerable;
begin
  Result := TValueEnumerable.Create(Self);
end;

function TGAbstractTreeMap.GetEntries: IEntryEnumerable;
begin
  Result := TEntryEnumerable.Create(Self);
end;

function TGAbstractTreeMap.FindNearestLT(const aPattern: TKey; out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.FindLess(aPattern);
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

function TGAbstractTreeMap.FindNearestLE(const aPattern: TKey; out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.FindLessOrEqual(aPattern);
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

function TGAbstractTreeMap.FindNearestGT(const aPattern: TKey; out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.FindGreater(aPattern);
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

function TGAbstractTreeMap.FindNearestGE(const aPattern: TKey; out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.FindGreaterOrEqual(aPattern);
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

destructor TGAbstractTreeMap.Destroy;
begin
  DoClear;
  FTree.Free;
  inherited;
end;

function TGAbstractTreeMap.ReverseKeys: IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyEnumerable.Create(Self, True);
end;

function TGAbstractTreeMap.ReverseValues: IValueEnumerable;
begin
  BeginIteration;
  Result := TValueEnumerable.Create(Self, True);
end;

function TGAbstractTreeMap.ReverseEntries: IEntryEnumerable;
begin
  BeginIteration;
  Result := TEntryEnumerable.Create(Self, True);
end;

function TGAbstractTreeMap.FindFirstKey(out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.Lowest;
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

function TGAbstractTreeMap.FirstKey: TKeyOptional;
var
  k: TKey;
begin
  if FindFirstKey(k) then
    Result.Assign(k);
end;

function TGAbstractTreeMap.FindLastKey(out aKey: TKey): Boolean;
var
  Node: PNode;
begin
  Node := FTree.Highest;
  Result := Node <> nil;
  if Result then
    aKey := Node^.Data.Key;
end;

function TGAbstractTreeMap.LastKey: TKeyOptional;
var
  k: TKey;
begin
  if FindLastKey(k) then
    Result.Assign(k);
end;

function TGAbstractTreeMap.FindFirstValue(out aValue: TValue): Boolean;
var
  Node: PNode;
begin
  Node := FTree.Lowest;
  Result := Node <> nil;
  if Result then
    aValue := Node^.Data.Value;
end;

function TGAbstractTreeMap.FirstValue: TValueOptional;
var
  v: TValue;
begin
  if FindFirstValue(v) then
    Result.Assign(v);
end;

function TGAbstractTreeMap.FindLastValue(out aValue: TValue): Boolean;
var
  Node: PNode;
begin
  Node := FTree.Highest;
  Result := Node <> nil;
  if Result then
    aValue := Node^.Data.Value;
end;

function TGAbstractTreeMap.LastValue: TValueOptional;
var
  v: TValue;
begin
  if FindLastValue(v) then
    Result.Assign(v);
end;

function TGAbstractTreeMap.FindMin(out aKey: TKey): Boolean;
begin
  Result := FindFirstKey(aKey);
end;

function TGAbstractTreeMap.Min: TKeyOptional;
begin
  Result := FirstKey;
end;

function TGAbstractTreeMap.FindMax(out aKey: TKey): Boolean;
begin
  Result := FindLastKey(aKey);
end;

function TGAbstractTreeMap.Max: TKeyOptional;
begin
  Result := LastKey;
end;

function TGAbstractTreeMap.FindCeil(const aKey: TKey; out aCeil: TKey; aInclusive: Boolean): Boolean;
begin
  if aInclusive then
    Result := FindNearestGE(aKey, aCeil)
  else
    Result := FindNearestGT(aKey, aCeil);
end;

function TGAbstractTreeMap.FindFloor(const aKey: TKey; out aFloor: TKey; aInclusive: Boolean): Boolean;
begin
  if aInclusive then
    Result := FindNearestLE(aKey, aFloor)
  else
    Result := FindNearestLT(aKey, aFloor);
end;

function TGAbstractTreeMap.Tail(const aLowBound: TKey; aInclusive: Boolean): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyTailEnumerable.Create(aLowBound, Self, aInclusive);
end;

{ TGBaseTreeMap.TKeyHeadEnumerable }

function TGBaseTreeMap.TKeyHeadEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGBaseTreeMap.TKeyHeadEnumerable.Create(const aHighBound: TKey; aMap: TAbstractTreeMap;
  aInclusive: Boolean);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumerator;
  FHighBound := aHighBound;
  FInclusive := aInclusive;
end;

destructor TGBaseTreeMap.TKeyHeadEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGBaseTreeMap.TKeyHeadEnumerable.MoveNext: Boolean;
begin
  if FDone or not FEnum.MoveNext then
    exit(False);
  if FInclusive then
    Result := not TKeyCmpRel.Less(FHighBound, FEnum.Current^.Data.Key)
  else
    Result := TKeyCmpRel.Less(FEnum.Current^.Data.Key, FHighBound);
  FDone := not Result;
end;

procedure TGBaseTreeMap.TKeyHeadEnumerable.Reset;
begin
  FEnum.Reset;
  FDone := False;
end;

{ TGBaseTreeMap.TKeyRangeEnumerable }

constructor TGBaseTreeMap.TKeyRangeEnumerable.Create(const aLowBound, aHighBound: TKey;
  aMap: TAbstractTreeMap; aBounds: TRangeBounds);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumeratorAt(aLowBound, rbLow in aBounds);
  FHighBound := aHighBound;
  FInclusive := rbHigh in aBounds;
end;

{ TGBaseTreeMap }

class function TGBaseTreeMap.DoCompare(const L, R: TKey): Boolean;
begin
  Result := TKeyCmpRel.Less(L, R);
end;

class function TGBaseTreeMap.Comparator: TComparator;
begin
  Result := @DoCompare;
end;

constructor TGBaseTreeMap.Create;
begin
  FTree := TBaseTree.Create;
end;

constructor TGBaseTreeMap.Create(aCapacity: SizeInt);
begin
  FTree := TBaseTree.Create(aCapacity);
end;

constructor TGBaseTreeMap.Create(const a: array of TEntry);
begin
  FTree := TBaseTree.Create;
  DoAddAll(a);
end;

constructor TGBaseTreeMap.Create(e: IEntryEnumerable);
begin
  FTree := TBaseTree.Create;
  DoAddAll(e);
end;

constructor TGBaseTreeMap.CreateCopy(aMap: TGBaseTreeMap);
begin
  FTree := TBaseTree(aMap.FTree).Clone;
end;

function TGBaseTreeMap.Clone: TGBaseTreeMap;
begin
  Result := TGBaseTreeMap.CreateCopy(Self);
end;

function TGBaseTreeMap.Head(const aHighBound: TKey; aInclusive: Boolean): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive);
end;

function TGBaseTreeMap.Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds);
end;

function TGBaseTreeMap.HeadMap(const aHighBound: TKey; aInclusive: Boolean): TGBaseTreeMap;
begin
  Result := TGBaseTreeMap.Create;
  with TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGBaseTreeMap.TailMap(const aLowBound: TKey; aInclusive: Boolean): TGBaseTreeMap;
begin
  Result := TGBaseTreeMap.Create;
  with TKeyTailEnumerable.Create(aLowBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGBaseTreeMap.SubMap(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): TGBaseTreeMap;
begin
  Result := TGBaseTreeMap.Create;
  with TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

{ TGObjectTreeMap }

procedure TGObjectTreeMap.SetOwnsKeys(aValue: Boolean);
begin
  if FOwnsKeys = aValue then exit;
  if aValue and (System.GetTypeKind(TKey) <> tkClass) then
    raise ELGObjectMapError.Create(SETKeyTypeMustBeClass);
  FOwnsKeys := aValue;
end;

procedure TGObjectTreeMap.SetOwnsValues(aValue: Boolean);
begin
  if FOwnsValues = aValue then exit;
  if aValue and (System.GetTypeKind(TValue) <> tkClass) then
    raise ELGObjectMapError.Create(SETValueTypeMustBeClass);
  FOwnsValues := aValue;
end;

procedure TGObjectTreeMap.EntryRemoving(p: PEntry);
begin
  if OwnsKeys then
    TObject((@p^.Key)^).Free;
  if OwnsValues then
    TObject((@p^.Value)^).Free;
end;

procedure TGObjectTreeMap.SetOwnership(aOwns: TMapObjOwnership);
begin
  OwnsKeys := moOwnsKeys in aOwns;
  OwnsValues := moOwnsValues in aOwns;
end;

function TGObjectTreeMap.DoRemove(const aKey: TKey): Boolean;
var
  v: TValue;
begin
  Result := DoExtract(aKey, v);
  if Result then
    begin
      if OwnsKeys then
        TObject((@aKey)^).Free;
      if OwnsValues then
        TObject((@v)^).Free;
    end;
end;

function TGObjectTreeMap.DoRemoveIf(aTest: TEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectTreeMap.DoRemoveIf(aTest: TOnEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectTreeMap.DoRemoveIf(aTest: TNestEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

procedure TGObjectTreeMap.DoClear;
var
  Node: PNode;
begin
  if OwnsKeys or OwnsValues then
    for Node in FTree do
      begin
        if OwnsKeys then
          TObject((@Node^.Data.Key)^).Free;
        if OwnsValues then
          TObject((@Node^.Data.Value)^).Free;
      end;
  inherited;
end;

function TGObjectTreeMap.DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aNewValue)^)) then
        TObject((@p^.Value)^).Free;
      p^.Value := aNewValue;
    end;
end;

function TGObjectTreeMap.DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if not Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aValue)^)) then
        TObject((@p^.Value)^).Free;
    end;
  p^.Value := aValue;
end;

constructor TGObjectTreeMap.Create(aOwns: TMapObjOwnership);
begin
  inherited Create;
  SetOwnership(aOwns);
end;

constructor TGObjectTreeMap.Create(aCapacity: SizeInt; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity);
  SetOwnership(aOwns);
end;

constructor TGObjectTreeMap.Create(const a: array of TEntry; aOwns: TMapObjOwnership);
begin
  inherited Create(a);
  SetOwnership(aOwns);
end;

constructor TGObjectTreeMap.Create(e: IEntryEnumerable; aOwns: TMapObjOwnership);
begin
  inherited Create(e);
  SetOwnership(aOwns);
end;

constructor TGObjectTreeMap.CreateCopy(aMap: TGObjectTreeMap);
begin
  inherited CreateCopy(aMap);
  OwnsKeys := aMap.OwnsKeys;
  OwnsValues := aMap.OwnsValues;
end;

function TGObjectTreeMap.Clone: TGObjectTreeMap;
begin
  Result := TGObjectTreeMap.CreateCopy(Self)
end;


{ TGComparableTreeMap.TKeyHeadEnumerable }

function TGComparableTreeMap.TKeyHeadEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGComparableTreeMap.TKeyHeadEnumerable.Create(const aHighBound: TKey; aMap: TAbstractTreeMap;
  aInclusive: Boolean);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumerator;
  FHighBound := aHighBound;
  FInclusive := aInclusive;
end;

destructor TGComparableTreeMap.TKeyHeadEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGComparableTreeMap.TKeyHeadEnumerable.MoveNext: Boolean;
begin
  if FDone or not FEnum.MoveNext then
    exit(False);
  if FInclusive then
    Result := not(FHighBound < FEnum.Current^.Data.Key)
  else
    Result := FEnum.Current^.Data.Key < FHighBound;
  FDone := not Result;
end;

procedure TGComparableTreeMap.TKeyHeadEnumerable.Reset;
begin
  FEnum.Reset;
  FDone := False;
end;

{ TGComparableTreeMap.TKeyRangeEnumerable }

constructor TGComparableTreeMap.TKeyRangeEnumerable.Create(const aLowBound, aHighBound: TKey;
  aMap: TAbstractTreeMap; aBounds: TRangeBounds);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumeratorAt(aLowBound, rbLow in aBounds);
  FHighBound := aHighBound;
  FInclusive := rbHigh in aBounds;
end;

{ TGComparableTreeMap }

class function TGComparableTreeMap.DoCompare(const L, R: TKey): Boolean;
begin
  Result := L < R;
end;

class function TGComparableTreeMap.Comparator: TComparator;
begin
  Result := @DoCompare;
end;

constructor TGComparableTreeMap.Create;
begin
  FTree := TComparableTree.Create;
end;

constructor TGComparableTreeMap.Create(aCapacity: SizeInt);
begin
  FTree := TComparableTree.Create(aCapacity);
end;

constructor TGComparableTreeMap.Create(const a: array of TEntry);
begin
  Create;
  DoAddAll(a);
end;

constructor TGComparableTreeMap.Create(e: IEntryEnumerable);
begin
  Create;
  DoAddAll(e);
end;

constructor TGComparableTreeMap.CreateCopy(aMap: TGComparableTreeMap);
begin
  inherited Create;
  FTree := TComparableTree(aMap.FTree).Clone;
end;

function TGComparableTreeMap.Clone: TGComparableTreeMap;
begin
  Result := TGComparableTreeMap.CreateCopy(Self);
end;

function TGComparableTreeMap.Head(const aHighBound: TKey; aInclusive: Boolean): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive);
end;

function TGComparableTreeMap.Range(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds);
end;

function TGComparableTreeMap.HeadMap(const aHighBound: TKey; aInclusive: Boolean): TGComparableTreeMap;
begin
  Result := TGComparableTreeMap.Create;
  with TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
      finally
        Free;
      end;
end;

function TGComparableTreeMap.TailMap(const aLowBound: TKey; aInclusive: Boolean): TGComparableTreeMap;
begin
  Result := TGComparableTreeMap.Create;
  with TKeyTailEnumerable.Create(aLowBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGComparableTreeMap.SubMap(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): TGComparableTreeMap;
begin
  Result := TGComparableTreeMap.Create;
  with TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

{ TGRegularTreeMap.TKeyHeadEnumerable }

function TGRegularTreeMap.TKeyHeadEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGRegularTreeMap.TKeyHeadEnumerable.Create(const aHighBound: TKey; aMap: TAbstractTreeMap;
  aInclusive: Boolean);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumerator;
  FLess := TRegularTree(aMap.FTree).Comparator;
  FHighBound := aHighBound;
  FInclusive := aInclusive;
end;

destructor TGRegularTreeMap.TKeyHeadEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGRegularTreeMap.TKeyHeadEnumerable.MoveNext: Boolean;
begin
  if FDone or not FEnum.MoveNext then
    exit(False);
  if FInclusive then
    Result := not FLess(FHighBound, FEnum.Current^.Data.Key)
  else
    Result := FLess(FEnum.Current^.Data.Key, FHighBound);
  FDone := not Result;
end;

procedure TGRegularTreeMap.TKeyHeadEnumerable.Reset;
begin
  FEnum.Reset;
  FDone := False;
end;

{ TGRegularTreeMap.TKeyRangeEnumerable }

constructor TGRegularTreeMap.TKeyRangeEnumerable.Create(const aLowBound, aHighBound: TKey;
  aMap: TAbstractTreeMap; aBounds: TRangeBounds);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumeratorAt(aLowBound, rbLow in aBounds);
  FLess := TRegularTree(aMap.FTree).Comparator;
  FHighBound := aHighBound;
  FInclusive := rbHigh in aBounds;
end;

{ TGRegularTreeMap }

function TGRegularTreeMap.Comparator: TLess;
begin
  Result := TRegularTree(FTree).Comparator;
end;

constructor TGRegularTreeMap.Create;
begin
  FTree := TRegularTree.Create(specialize TGDefaults<TKey>.Less);
end;

constructor TGRegularTreeMap.Create(aLess: TLess);
begin
  FTree := TRegularTree.Create(aLess);
end;

constructor TGRegularTreeMap.Create(aCapacity: SizeInt; aLess: TLess);
begin
  FTree := TRegularTree.Create(aCapacity, aLess);
end;

constructor TGRegularTreeMap.Create(const a: array of TEntry; aLess: TLess);
begin
  Create(aLess);
  DoAddAll(a);
end;

constructor TGRegularTreeMap.Create(e: IEntryEnumerable; aLess: TLess);
begin
  Create(aLess);
  DoAddAll(e);
end;

constructor TGRegularTreeMap.CreateCopy(aMap: TGRegularTreeMap);
begin
  FTree := TRegularTree(aMap.FTree).Clone;
end;

function TGRegularTreeMap.Clone: TGRegularTreeMap;
begin
  Result := TGRegularTreeMap.CreateCopy(Self);
end;

function TGRegularTreeMap.Head(const aHighBound: TKey; aInclusive: Boolean): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive);
end;

function TGRegularTreeMap.Range(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds);
end;

function TGRegularTreeMap.HeadMap(const aHighBound: TKey; aInclusive: Boolean): TGRegularTreeMap;
begin
  Result := TGRegularTreeMap.Create(Comparator);
  with TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGRegularTreeMap.TailMap(const aLowBound: TKey; aInclusive: Boolean): TGRegularTreeMap;
begin
  Result := TGRegularTreeMap.Create(Comparator);
  with TKeyTailEnumerable.Create(aLowBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGRegularTreeMap.SubMap(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): TGRegularTreeMap;
begin
  Result := TGRegularTreeMap.Create(Comparator);
  with TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

{ TGObjectRegularTreeMap }

procedure TGObjectRegularTreeMap.SetOwnsKeys(aValue: Boolean);
begin
  if FOwnsKeys = aValue then exit;
  if aValue and (System.GetTypeKind(TKey) <> tkClass) then
    raise ELGObjectMapError.Create(SETKeyTypeMustBeClass);
  FOwnsKeys := aValue;
end;

procedure TGObjectRegularTreeMap.SetOwnsValues(aValue: Boolean);
begin
  if FOwnsValues = aValue then exit;
  if aValue and (System.GetTypeKind(TValue) <> tkClass) then
    raise ELGObjectMapError.Create(SETValueTypeMustBeClass);
  FOwnsValues := aValue;
end;

procedure TGObjectRegularTreeMap.EntryRemoving(p: PEntry);
begin
  if OwnsKeys then
    TObject((@p^.Key)^).Free;
  if OwnsValues then
    TObject((@p^.Value)^).Free;
end;

procedure TGObjectRegularTreeMap.SetOwnership(aOwns: TMapObjOwnership);
begin
  OwnsKeys := moOwnsKeys in aOwns;
  OwnsValues := moOwnsValues in aOwns;
end;

function TGObjectRegularTreeMap.DoRemove(const aKey: TKey): Boolean;
var
  v: TValue;
begin
  Result := DoExtract(aKey, v);
  if Result then
    begin
      if OwnsKeys then
        TObject((@aKey)^).Free;
      if OwnsValues then
        TObject((@v)^).Free;
    end;
end;

function TGObjectRegularTreeMap.DoRemoveIf(aTest: TEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectRegularTreeMap.DoRemoveIf(aTest: TOnEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectRegularTreeMap.DoRemoveIf(aTest: TNestEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

procedure TGObjectRegularTreeMap.DoClear;
var
  Node: PNode;
begin
  if OwnsKeys or OwnsValues then
    for Node in FTree do
      begin
        if OwnsKeys then
          TObject((@Node^.Data.Key)^).Free;
        if OwnsValues then
          TObject((@Node^.Data.Value)^).Free;
      end;
  inherited;
end;

function TGObjectRegularTreeMap.DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aNewValue)^)) then
        TObject((@p^.Value)^).Free;
      p^.Value := aNewValue;
    end;
end;

function TGObjectRegularTreeMap.DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if not Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aValue)^)) then
        TObject((@p^.Value)^).Free;
    end;
  p^.Value := aValue;
end;

constructor TGObjectRegularTreeMap.Create(aOwns: TMapObjOwnership);
begin
  inherited Create;
  SetOwnership(aOwns);
end;

constructor TGObjectRegularTreeMap.Create(c: TLess; aOwns: TMapObjOwnership);
begin
  inherited Create(c);
  SetOwnership(aOwns);
end;

constructor TGObjectRegularTreeMap.Create(aCapacity: SizeInt; c: TLess; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, c);
  SetOwnership(aOwns);
end;

constructor TGObjectRegularTreeMap.Create(const a: array of TEntry; c: TLess; aOwns: TMapObjOwnership);
begin
  inherited Create(a, c);
  SetOwnership(aOwns);
end;

constructor TGObjectRegularTreeMap.Create(e: IEntryEnumerable; c: TLess; aOwns: TMapObjOwnership);
begin
  inherited Create(e, c);
  SetOwnership(aOwns);
end;

constructor TGObjectRegularTreeMap.CreateCopy(aMap: TGObjectRegularTreeMap);
begin
  inherited CreateCopy(aMap);
  OwnsKeys := aMap.OwnsKeys;
  OwnsValues := aMap.OwnsValues;
end;

function TGObjectRegularTreeMap.Clone: TGObjectRegularTreeMap;
begin
  Result := TGObjectRegularTreeMap.CreateCopy(Self);
end;

{ TGDelegatedTreeMap.TKeyHeadEnumerable }

function TGDelegatedTreeMap.TKeyHeadEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Data.Key;
end;

constructor TGDelegatedTreeMap.TKeyHeadEnumerable.Create(const aHighBound: TKey; aMap: TAbstractTreeMap;
  aInclusive: Boolean);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumerator;
  FLess := TDelegatedTree(aMap.FTree).Comparator;
  FHighBound := aHighBound;
  FInclusive := aInclusive;
end;

destructor TGDelegatedTreeMap.TKeyHeadEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGDelegatedTreeMap.TKeyHeadEnumerable.MoveNext: Boolean;
begin
  if FDone or not FEnum.MoveNext then
    exit(False);
  if FInclusive then
    Result := not FLess(FHighBound, FEnum.Current^.Data.Key)
  else
    Result := FLess(FEnum.Current^.Data.Key, FHighBound);
  FDone := not Result;
end;

procedure TGDelegatedTreeMap.TKeyHeadEnumerable.Reset;
begin
  FEnum.Reset;
  FDone := False;
end;

{ TGDelegatedTreeMap.TKeyRangeEnumerable }

constructor TGDelegatedTreeMap.TKeyRangeEnumerable.Create(const aLowBound, aHighBound: TKey;
  aMap: TAbstractTreeMap; aBounds: TRangeBounds);
begin
  inherited Create(aMap);
  FEnum := aMap.FTree.GetEnumeratorAt(aLowBound, rbLow in aBounds);
  FLess := TDelegatedTree(aMap.FTree).Comparator;
  FHighBound := aHighBound;
  FInclusive := rbHigh in aBounds;
end;

{ TGDelegatedTreeMap }

constructor TGDelegatedTreeMap.Create;
begin
  FTree := TDelegatedTree.Create(specialize TGDefaults<TKey>.OnLess);
end;

constructor TGDelegatedTreeMap.Create(aLess: TOnLess);
begin
  FTree := TDelegatedTree.Create(aLess);
end;

constructor TGDelegatedTreeMap.Create(aCapacity: SizeInt; aLess: TOnLess);
begin
  FTree := TDelegatedTree.Create(aCapacity, aLess);
end;

constructor TGDelegatedTreeMap.Create(const a: array of TEntry; aLess: TOnLess);
begin
  Create(aLess);
  DoAddAll(a);
end;

constructor TGDelegatedTreeMap.Create(e: IEntryEnumerable; aLess: TOnLess);
begin
  Create(aLess);
  DoAddAll(e);
end;

constructor TGDelegatedTreeMap.CreateCopy(aMap: TGDelegatedTreeMap);
begin
  FTree := TDelegatedTree(aMap.FTree).Clone;
end;

function TGDelegatedTreeMap.Comparator: TOnLess;
begin
  Result := TDelegatedTree(FTree).Comparator;
end;

function TGDelegatedTreeMap.Clone: TGDelegatedTreeMap;
begin
  Result := TGDelegatedTreeMap.CreateCopy(Self);
end;

function TGDelegatedTreeMap.Head(const aHighBound: TKey; aInclusive: Boolean): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive);
end;

function TGDelegatedTreeMap.Range(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): IKeyEnumerable;
begin
  BeginIteration;
  Result := TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds);
end;

function TGDelegatedTreeMap.HeadMap(const aHighBound: TKey; aInclusive: Boolean): TGDelegatedTreeMap;
begin
  Result := TGDelegatedTreeMap.Create(Comparator);
  with TKeyHeadEnumerable.Create(aHighBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGDelegatedTreeMap.TailMap(const aLowBound: TKey; aInclusive: Boolean): TGDelegatedTreeMap;
begin
  Result := TGDelegatedTreeMap.Create(Comparator);
  with TKeyTailEnumerable.Create(aLowBound, Self, aInclusive) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

function TGDelegatedTreeMap.SubMap(const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds): TGDelegatedTreeMap;
begin
  Result := TGDelegatedTreeMap.Create(Comparator);
  with TKeyRangeEnumerable.Create(aLowBound, aHighBound, Self, aIncludeBounds) do
    try
      while MoveNext do
        Result.Add(FEnum.Current^.Data);
    finally
      Free;
    end;
end;

{ TGObjectDelegatedTreeMap }

procedure TGObjectDelegatedTreeMap.SetOwnsKeys(aValue: Boolean);
begin
  if FOwnsKeys = aValue then exit;
  if aValue and (System.GetTypeKind(TKey) <> tkClass) then
    raise ELGObjectMapError.Create(SETKeyTypeMustBeClass);
  FOwnsKeys := aValue;
end;

procedure TGObjectDelegatedTreeMap.SetOwnsValues(aValue: Boolean);
begin
  if FOwnsValues = aValue then exit;
  if aValue and (System.GetTypeKind(TValue) <> tkClass) then
    raise ELGObjectMapError.Create(SETValueTypeMustBeClass);
  FOwnsValues := aValue;
end;

procedure TGObjectDelegatedTreeMap.EntryRemoving(p: PEntry);
begin
  if OwnsKeys then
    TObject((@p^.Key)^).Free;
  if OwnsValues then
    TObject((@p^.Value)^).Free;
end;

procedure TGObjectDelegatedTreeMap.SetOwnership(aOwns: TMapObjOwnership);
begin
  OwnsKeys := moOwnsKeys in aOwns;
  OwnsValues := moOwnsValues in aOwns;
end;

function TGObjectDelegatedTreeMap.DoRemove(const aKey: TKey): Boolean;
var
  v: TValue;
begin
  Result := DoExtract(aKey, v);
  if Result then
    begin
      if OwnsKeys then
        TObject((@aKey)^).Free;
      if OwnsValues then
        TObject((@v)^).Free;
    end;
end;

function TGObjectDelegatedTreeMap.DoRemoveIf(aTest: TEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectDelegatedTreeMap.DoRemoveIf(aTest: TOnEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

function TGObjectDelegatedTreeMap.DoRemoveIf(aTest: TNestEntryTest): SizeInt;
begin
  Result := FTree.RemoveIfe(aTest, @EntryRemoving);
end;

procedure TGObjectDelegatedTreeMap.DoClear;
var
  Node: PNode;
begin
  if OwnsKeys or OwnsValues then
    for Node in FTree do
      begin
        if OwnsKeys then
          TObject((@Node^.Data.Key)^).Free;
        if OwnsValues then
          TObject((@Node^.Data.Value)^).Free;
      end;
  inherited;
end;

function TGObjectDelegatedTreeMap.DoSetValue(const aKey: TKey; const aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aNewValue)^)) then
        TObject((@p^.Value)^).Free;
      p^.Value := aNewValue;
    end;
end;

function TGObjectDelegatedTreeMap.DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if not Result then
    begin
      if OwnsValues and (TObject((@p^.Value)^) <> TObject((@aValue)^)) then
        TObject((@p^.Value)^).Free;
    end;
  p^.Value := aValue;
end;

constructor TGObjectDelegatedTreeMap.Create(aOwns: TMapObjOwnership);
begin
  inherited Create;
  SetOwnership(aOwns);
end;

constructor TGObjectDelegatedTreeMap.Create(c: TOnLess; aOwns: TMapObjOwnership);
begin
  inherited Create(c);
  SetOwnership(aOwns);
end;

constructor TGObjectDelegatedTreeMap.Create(aCapacity: SizeInt; c: TOnLess; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, c);
  SetOwnership(aOwns);
end;

constructor TGObjectDelegatedTreeMap.Create(const a: array of TEntry; c: TOnLess; aOwns: TMapObjOwnership);
begin
  inherited Create(a, c);
  SetOwnership(aOwns);
end;

constructor TGObjectDelegatedTreeMap.Create(e: IEntryEnumerable; c: TOnLess; aOwns: TMapObjOwnership);
begin
  inherited Create(e, c);
  SetOwnership(aOwns);
end;

constructor TGObjectDelegatedTreeMap.CreateCopy(aMap: TGObjectDelegatedTreeMap);
begin
  inherited CreateCopy(aMap);
  OwnsKeys := aMap.OwnsKeys;
  OwnsValues := aMap.OwnsValues;
end;

function TGObjectDelegatedTreeMap.Clone: TGObjectDelegatedTreeMap;
begin
  Result := TGObjectDelegatedTreeMap.CreateCopy(Self);
end;

{ TGLiteTreeMap.TEntryEnumerator }

function TGLiteTreeMap.TEntryEnumerator.GetCurrent: TEntry;
begin
  Result := FTree^.NodeList[FCurrNode].Data;
end;

procedure TGLiteTreeMap.TEntryEnumerator.Init(const aMap: TGLiteTreeMap; aNode: SizeInt);
begin
  FTree := @aMap.FTree;
  FCurrNode := aNode;
  FInCycle := False;
end;

function TGLiteTreeMap.TEntryEnumerator.MoveNext: Boolean;
begin
  if FInCycle then
    FCurrNode := FTree^.Successor(FCurrNode)
  else
    FInCycle := True;
  Result := FCurrNode <> 0;
end;

{ TGLiteTreeMap.TReverseEntries }

function TGLiteTreeMap.TReverseEntries.GetCurrent: TEntry;
begin
  Result := FTree^.NodeList[FCurrNode].Data;
end;

procedure TGLiteTreeMap.TReverseEntries.Init(const aMap: TGLiteTreeMap);
begin
  FTree := @aMap.FTree;
  FCurrNode := FTree^.Highest;
  FInCycle := False;
end;

function TGLiteTreeMap.TReverseEntries.GetEnumerator: TReverseEntries;
begin
  Result := Self;
end;

function TGLiteTreeMap.TReverseEntries.MoveNext: Boolean;
begin
  if FInCycle then
    FCurrNode := FTree^.Predecessor(FCurrNode)
  else
    FInCycle := True;
  Result := FCurrNode <> 0;
end;

{ TGLiteTreeMap.TUnordEntries }

function TGLiteTreeMap.TUnordEntries.GetCurrent: TEntry;
begin
  Result := FEnum.Current^;
end;

procedure TGLiteTreeMap.TUnordEntries.Init(const aMap: TGLiteTreeMap);
begin
  FEnum := aMap.FTree.UnOrdered;
end;

function TGLiteTreeMap.TUnordEntries.GetEnumerator: TUnordEntries;
begin
  Result := Self;
end;

function TGLiteTreeMap.TUnordEntries.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

{ TGLiteTreeMap.TKeys }

function TGLiteTreeMap.TKeys.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Key;
end;

procedure TGLiteTreeMap.TKeys.Init(const aMap: TGLiteTreeMap);
begin
  FEnum := aMap.FTree.GetEnumerator;
end;

function TGLiteTreeMap.TKeys.GetEnumerator: TKeys;
begin
  Result := Self;
end;

function TGLiteTreeMap.TKeys.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

{ TGLiteTreeMap.TUnordKeys }

function TGLiteTreeMap.TUnordKeys.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Key;
end;

procedure TGLiteTreeMap.TUnordKeys.Init(const aMap: TGLiteTreeMap);
begin
  FEnum := aMap.FTree.UnOrdered;
end;

function TGLiteTreeMap.TUnordKeys.GetEnumerator: TUnordKeys;
begin
  Result := Self;
end;

function TGLiteTreeMap.TUnordKeys.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

{ TGLiteTreeMap.TValues }

function TGLiteTreeMap.TValues.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Value;
end;

procedure TGLiteTreeMap.TValues.Init(const aMap: TGLiteTreeMap);
begin
  FEnum := aMap.FTree.GetEnumerator;
end;

function TGLiteTreeMap.TValues.GetEnumerator: TValues;
begin
  Result := Self;
end;

function TGLiteTreeMap.TValues.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

{ TGLiteTreeMap.TUnordValues }

function TGLiteTreeMap.TUnordValues.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Value;
end;

procedure TGLiteTreeMap.TUnordValues.Init(const aMap: TGLiteTreeMap);
begin
  FEnum := aMap.FTree.UnOrdered;
end;

function TGLiteTreeMap.TUnordValues.GetEnumerator: TUnordValues;
begin
  Result := Self;
end;

function TGLiteTreeMap.TUnordValues.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

{ TGLiteTreeMap.THead }

function TGLiteTreeMap.THead.GetCurrent: TEntry;
begin
  Result := FTree^.NodeList[FCurrNode].Data;
end;

procedure TGLiteTreeMap.THead.Init(const aMap: TGLiteTreeMap; const aBound: TKey; aInclusive: Boolean);
begin
  FTree := @aMap.FTree;
  FCurrNode := 0;
  FHighBound := aBound;
  FInclusive := aInclusive;
  FDone := FTree^.Count = 0;
end;

function TGLiteTreeMap.THead.GetEnumerator: THead;
begin
  Result := Self;
end;

function TGLiteTreeMap.THead.MoveNext: Boolean;
var
  Next: SizeInt;
begin
  if FDone then exit(False);
  if FCurrNode = 0 then
    Next := FTree^.Lowest
  else
    Next := FTree^.Successor(FCurrNode);
  if Next = 0 then
    begin
      FDone := True;
      exit(False);
    end;
  if FInclusive then
    Result := not TKeyCmpRel.Less(FHighBound, FTree^.NodeList[Next].Data.Key)
  else
    Result := TKeyCmpRel.Less(FTree^.NodeList[Next].Data.Key, FHighBound);
  if Result then
    FCurrNode := Next
  else
    FDone := True;
end;

{ TGLiteTreeMap.TTail }

function TGLiteTreeMap.TTail.GetCurrent: TEntry;
begin
  Result := FTree^.NodeList[FCurrNode].Data;
end;

procedure TGLiteTreeMap.TTail.Init(const aMap: TGLiteTreeMap; const aBound: TKey; aInclusive: Boolean);
begin
  FTree := @aMap.FTree;
  FCurrNode := 0;
  if aInclusive then
    FFirstNode := FTree^.FindGreaterOrEqual(aBound)
  else
    FFirstNode := FTree^.FindGreater(aBound);
  FInCycle := False;
end;

function TGLiteTreeMap.TTail.GetEnumerator: TTail;
begin
  Result := Self;
end;

function TGLiteTreeMap.TTail.MoveNext: Boolean;
var
  Next: SizeInt;
begin
  Next := 0;
  if FCurrNode <> 0 then
    Next := FTree^.Successor(FCurrNode)
  else
    if not FInCycle then
      begin
        Next := FFirstNode;
        FInCycle := True;
      end;
  Result := Next <> 0;
  if Result then
    FCurrNode := Next;
end;

{ TGLiteTreeMap.TRange }

function TGLiteTreeMap.TRange.GetCurrent: TEntry;
begin
  Result := FTree^.NodeList[FCurrNode].Data;
end;

procedure TGLiteTreeMap.TRange.Init(const aMap: TGLiteTreeMap; const aLowBound, aHighBound: TKey;
  aIncludeBounds: TRangeBounds);
begin
  FTree := @aMap.FTree;
  FCurrNode := 0;
  if rbLow in aIncludeBounds then
    FFirstNode := FTree^.FindGreaterOrEqual(aLowBound)
  else
    FFirstNode := FTree^.FindGreater(aLowBound);
  FHighBound := aHighBound;
  FInclusive := rbHigh in aIncludeBounds;
  FDone := False;
end;

function TGLiteTreeMap.TRange.GetEnumerator: TRange;
begin
  Result := Self;
end;

function TGLiteTreeMap.TRange.MoveNext: Boolean;
var
  Next: SizeInt;
begin
  if FDone then exit(False);
  if FCurrNode = 0 then
    Next := FFirstNode
  else
    Next := FTree^.Successor(FCurrNode);
  if Next = 0 then
    begin
      FDone := True;
      exit(False);
    end;
  if FInclusive then
    Result := not TKeyCmpRel.Less(FHighBound, FTree^.NodeList[Next].Data.Key)
  else
    Result := TKeyCmpRel.Less(FTree^.NodeList[Next].Data.Key, FHighBound);
  if Result then
    FCurrNode := Next;
  FDone := not Result;
end;

{ TGLiteTreeMap }

function TGLiteTreeMap.GetCount: SizeInt;
begin
  Result := FTree.Count;
end;

function TGLiteTreeMap.GetCapacity: SizeInt;
begin
  Result := FTree.Capacity;
end;

function TGLiteTreeMap.GetHeight: SizeInt;
begin
  Result := FTree.Height;
end;

function TGLiteTreeMap.GetConsistent: Boolean;
begin
  Result := FTree.CheckState = asConsistent;
end;

function TGLiteTreeMap.GetValue(const aKey: TKey): TValue;
begin
  if not TryGetValue(aKey, Result) then
    raise ELGMapError.Create(SEKeyNotFound);
end;

function TGLiteTreeMap.FindNearestLT(const aKey: TKey; out k: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.FindLess(aKey);
  Result := I <> 0;
  if Result then
    k := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.FindNearestLE(const aKey: TKey; out k: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.FindLessOrEqual(aKey);
  Result := I <> 0;
  if Result then
    k := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.FindNearestGT(const aKey: TKey; out k: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.FindGreater(aKey);
  Result := I <> 0;
  if Result then
    k := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.FindNearestGE(const aKey: TKey; out k: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.FindGreaterOrEqual(aKey);
  Result := I <> 0;
  if Result then
    k := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.GetEnumerator: TEntryEnumerator;
begin
  Result.Init(Self, FTree.Lowest);
end;

function TGLiteTreeMap.ReverseEntries: TReverseEntries;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.UnOrdered: TUnordEntries;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.Keys: TKeys;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.UnordKeys: TUnordKeys;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.Values: TValues;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.UnordValues: TUnordValues;
begin
  Result.Init(Self);
end;

function TGLiteTreeMap.ToArray: TEntryArray;
var
  r: TEntryArray = nil;
  rCnt: SizeInt = 0;
  procedure Visit(const e: TEntry);
  begin
    r[rCnt] := e;
    Inc(rCnt);
  end;
begin
  if FTree.Count = 0 then exit(nil);
  System.SetLength(r, Count);
  FTree.Traverse(@Visit);
  Result := r;
end;

function TGLiteTreeMap.IsEmpty: Boolean;
begin
  Result := FTree.Count = 0;
end;

function TGLiteTreeMap.NonEmpty: Boolean;
begin
  Result := FTree.Count <> 0;
end;

procedure TGLiteTreeMap.Clear;
begin
  FTree.Clear;
end;

procedure TGLiteTreeMap.MakeEmpty;
begin
  FTree.MakeEmpty;
end;

procedure TGLiteTreeMap.EnsureCapacity(aValue: SizeInt);
begin
  FTree.EnsureCapacity(aValue);
end;

procedure TGLiteTreeMap.TrimToFit;
begin
  FTree.TrimToFit;
end;

function TGLiteTreeMap.TryGetValue(const aKey: TKey; out aValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := FTree.Find(aKey);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGLiteTreeMap.TryGetMutValue(const aKey: TKey; out p: PValue): Boolean;
var
  pe: PEntry;
begin
  pe := FTree.Find(aKey);
  Result := pe <> nil;
  if Result then
    p := @pe^.Value;
end;

function TGLiteTreeMap.GetValueDef(const aKey: TKey; const aDefault: TValue): TValue;
begin
  if not TryGetValue(aKey, Result) then
    Result := aDefault;
end;

function TGLiteTreeMap.GetMutValueDef(const aKey: TKey; const aDefault: TValue): PValue;
var
  p: PEntry;
begin
  if not FTree.FindOrAdd(aKey, p) then
    p^.Value := aDefault;
  Result := @p^.Value;
end;

function TGLiteTreeMap.FindOrAddMutValue(const aKey: TKey; out p: PValue): Boolean;
var
  pe: PEntry;
begin
  Result := FTree.FindOrAdd(aKey, pe);
  p := @pe^.Value;
end;

function TGLiteTreeMap.Add(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FTree.FindOrAdd(aKey, p);
  if Result then
    p^.Value := aValue;
end;

function TGLiteTreeMap.Add(const e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

procedure TGLiteTreeMap.AddOrSetValue(const aKey: TKey; const aValue: TValue);
var
  p: PEntry;
begin
  FTree.FindOrAdd(aKey, p);
  p^.Value := aValue;
end;

function TGLiteTreeMap.AddOrSetValue(const e: TEntry): Boolean;
var
  p: PEntry;
begin
  Result := not FTree.FindOrAdd(e.Key, p);
  p^.Value := e.Value;
end;

function TGLiteTreeMap.AddAll(const a: array of TEntry): SizeInt;
var
  I: SizeInt;
begin
  Result := Count;
  for I := 0 to System.High(a) do
    Add(a[I]);
  Result := Count - Result;
end;

function TGLiteTreeMap.AddAll(e: IEntryEnumerable): SizeInt;
begin
  Result := Count;
  with e.GetEnumerator do
    try
      while MoveNext do
        Add(Current);
    finally
      Free;
    end;
  Result := Count - Result;
end;

function TGLiteTreeMap.AddAll(constref aMap: TGLiteTreeMap): SizeInt;
var
  e: TEntry;
begin
  if @aMap = @Self then exit(0);
  Result := Count;
  for e in aMap do /////
    Add(e);
  Result := Count - Result;
end;

function TGLiteTreeMap.Replace(const aKey: TKey; const aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := FTree.Find(aKey);
  Result := p <> nil;
  if Result then
    p^.Value := aNewValue;
end;

function TGLiteTreeMap.Contains(const aKey: TKey): Boolean;
begin
  Result := FTree.Find(aKey) <> nil;
end;

function TGLiteTreeMap.NonContains(const aKey: TKey): Boolean;
begin
  Result := FTree.Find(aKey) = nil;
end;

function TGLiteTreeMap.ContainsAny(const a: array of TKey): Boolean;
var
  I: SizeInt;
begin
  if NonEmpty then
    for I := 0 to System.High(a) do
      if Contains(a[I]) then
        exit(True);
  Result := False;
end;

function TGLiteTreeMap.ContainsAny(e: IKeyEnumerable): Boolean;
begin
  if NonEmpty then
    with e.GetEnumerator do
      try
        while MoveNext do
          if Contains(Current) then exit(True);
      finally
        Free;
      end
  else
    e.Discard;
  Result := False;
end;

function TGLiteTreeMap.ContainsAny(constref aMap: TGLiteTreeMap): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then exit(True);
  if NonEmpty then
    for k in aMap.UnordKeys do
      if Contains(k) then exit(True);
  Result := False;
end;

function TGLiteTreeMap.ContainsAll(const a: array of TKey): Boolean;
var
  I: SizeInt;
begin
  if IsEmpty then exit(System.Length(a) = 0);
  for I := 0 to System.High(a) do
    if not Contains(a[I]) then exit(False);
  Result := True;
end;

function TGLiteTreeMap.ContainsAll(e: IKeyEnumerable): Boolean;
begin
  if IsEmpty then exit(e.None);
  with e.GetEnumerator do
    try
      while MoveNext do
        if not Contains(Current) then exit(False);
    finally
      Free;
    end;
  Result := True;
end;

function TGLiteTreeMap.ContainsAll(constref aMap: TGLiteTreeMap): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then exit(True);
  if IsEmpty then exit(aMap.IsEmpty);
  for k in aMap.UnordKeys do
    if not Contains(k) then exit(False);
  Result := True;
end;

function TGLiteTreeMap.Remove(const aKey: TKey): Boolean;
begin
  Result := FTree.Remove(aKey);
end;

function TGLiteTreeMap.RemoveAll(const a: array of TKey): SizeInt;
var
  I: SizeInt;
begin
  Result := Count;
  for I := 0 to System.High(a) do
    FTree.Remove(a[I]);
  Result -= Count;
end;

function TGLiteTreeMap.RemoveAll(e: IKeyEnumerable): SizeInt;
begin
  Result := Count;
  with e.GetEnumerator do
    try
      while MoveNext do
        FTree.Remove(Current);
    finally
      Free;
    end;
  Result -= Count;
end;

function TGLiteTreeMap.RemoveAll(constref aMap: TGLiteTreeMap): SizeInt;
var
  k: TKey;
begin
  Result := Count;
  if @aMap <> @Self then
    for k in aMap.UnordKeys do
      FTree.Remove(k)
  else
    MakeEmpty;
  Result -= Count;
end;

function TGLiteTreeMap.RemoveIf(aTest: TEntryTest): SizeInt;
var
  I: SizeInt;
begin
  Result := Count;
  for I := Result downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      FTree.RemoveAt(I);
  Result -= Count;
end;

function TGLiteTreeMap.RemoveIf(aTest: TOnEntryTest): SizeInt;
var
  I: SizeInt;
begin
  Result := Count;
  for I := Result downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      FTree.RemoveAt(I);
  Result -= Count;
end;

function TGLiteTreeMap.RemoveIf(aTest: TNestEntryTest): SizeInt;
var
  I: SizeInt;
begin
  Result := Count;
  for I := Result downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      FTree.RemoveAt(I);
  Result -= Count;
end;

function TGLiteTreeMap.Extract(const aKey: TKey; out v: TValue): Boolean;
var
  p: PEntry;
  I: SizeInt;
begin
  p := FTree.Find(aKey, I);
  Result := p <> nil;
  if Result then
    begin
      v := p^.Value;
      FTree.RemoveAt(I);
    end;
end;

function TGLiteTreeMap.ExtractIf(aTest: TEntryTest): TEntryArray;
var
  I, J: SizeInt;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  J := 0;
  for I := Count downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J * 2);
        Result[J] := FTree.NodeList[I].Data;
        Inc(J);
        FTree.RemoveAt(I);
      end;
  System.SetLength(Result, J);
end;

function TGLiteTreeMap.ExtractIf(aTest: TOnEntryTest): TEntryArray;
var
  I, J: SizeInt;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  J := 0;
  for I := Count downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J * 2);
        Result[J] := FTree.NodeList[I].Data;
        Inc(J);
        FTree.RemoveAt(I);
      end;
  System.SetLength(Result, J);
end;

function TGLiteTreeMap.ExtractIf(aTest: TNestEntryTest): TEntryArray;
var
  I, J: SizeInt;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  J := 0;
  for I := Count downto 1 do
    if aTest(FTree.NodeList[I].Data) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J * 2);
        Result[J] := FTree.NodeList[I].Data;
        Inc(J);
        FTree.RemoveAt(I);
      end;
  System.SetLength(Result, J);
end;

procedure TGLiteTreeMap.RetainAll(aCollection: IKeyCollection);
  function Test(const e: TEntry): Boolean;
  begin
    Test := aCollection.NonContains(e.Key);
  end;
begin
  RemoveIf(@Test);
end;

function TGLiteTreeMap.FindMinKey(out aKey: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.Lowest;
  Result := I <> 0;
  if Result then
    aKey := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.FindMaxKey(out aKey: TKey): Boolean;
var
  I: SizeInt;
begin
  I := FTree.Lowest;
  Result := I <> 0;
  if Result then
    aKey := FTree.NodeList[I].Data.Key;
end;

function TGLiteTreeMap.FindCeilKey(const aKey: TKey; out aCeil: TKey; aInclusive: Boolean): Boolean;
begin
  if aInclusive then
    Result := FindNearestGE(aKey, aCeil)
  else
    Result := FindNearestGT(aKey, aCeil);
end;

function TGLiteTreeMap.FindFloorKey(const aKey: TKey; out aFloor: TKey; aInclusive: Boolean): Boolean;
begin
  if aInclusive then
    Result := FindNearestLE(aKey, aFloor)
  else
    Result := FindNearestLT(aKey, aFloor);
end;

function TGLiteTreeMap.Head(const aHighBound: TKey; aInclusive: Boolean): THead;
begin
  Result.Init(Self, aHighBound, aInclusive);
end;

function TGLiteTreeMap.Tail(const aLowBound: TKey; aInclusive: Boolean): TTail;
begin
  Result.Init(Self, aLowBound, aInclusive);
end;

function TGLiteTreeMap.Range(const aLowBound, aHighBound: TKey; aIncludeBounds: TRangeBounds): TRange;
begin
  Result.Init(Self, aLowBound, aHighBound, aIncludeBounds);
end;

end.

