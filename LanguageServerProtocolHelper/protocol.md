LSP Helper Protocol
===================

Introduction
------------

The LSP helper communicates with the Language Server via stdin/stdout. In case
of an LSP helper inside an emulator, the helper communicates with the Language
Server via the (first) serial port.

The protocol is a binary protocol, consisting of 8-bit integers (BYTE), 32-bit integers
(sent as Little Endian), and Strings (sent as NULL-terminated ASCII/UTF-8
strings). File content is transferred by a 32-bit length (in bytes) followed by
the actual bytes of the file.

The Language server sends requests to the LSP Helper, which are answered by the
helper. In case the helper cannot answer the request, it sends `STATUS_Invalid`
(1) as a single byte. When a request has been handled, the language server can
send the next request.

Requests
--------

There are 5 supported requests, determined by the first byte of the communication.

| Value | Name                    | Description      |
| ----- | ----------------------- | ------------------
| 100   | INST_GetModuleInfo      | Send the content of a module file, and receive information about syntactic tokens, definitions, references, etc. |
| 101   | INST_AutoComplete       | Send the prefix of a module file, and return possible completions for the last token of the prefix. |
| 102   | INST_ReFormat           | Send the content of a module file and receive a list of tokens with their whitespace requirements before and after it, to aid in reformatting the file. |
| 103   | INST_SwitchEmbeddedMode | Switch the emulator to embedded mode where it only listens to RS232 and no other inputs. Only used by the Language Server if no emulator UI is provided. |
| 104   | INST_Exit               | Exit the LSP helper. |


GetModuleInfo
-------------

### Request

- BYTE: `INST_GetModuleInfo` (100)
- INTEGER: Length of the file
- Content of the file

### Response packets

- `STATUS_OK` (0): No arguments, end of response, everything fine
- `STATUS_Invalid` (1): No arguments, end of response, something went wrong
- `ANSWER_ModuleName` (10): Name of the compiled module (String)
- `ANSWER_ModuleImport` (11): Name of an imported module (String), used for
  dependency tracking
- `ANSWER_Error` (12):  Position (INTEGER) and error message (C String)
- `ANSWER_Warning` (60): Same for warning message (not used in Project Oberon)
- `ANSWER_Information` (61): Same for information message (not used in Project
  Oberon)
- `ANSWER_SymbolFileChanged` (13): No arguments, indicator that symbol file
  changed and dependent modules need to be re-analyzed
- `ANSWER_SyntaxElement` (14): Information about syntax element (see below)
- `ANSWER_ProcedureStart` (15): Last syntax element was keyword `PROCEDURE` that
  started a procedure (and not a procedure type declaration).
- `ANSWER_ProcedureEnd` (16): Position (INTEGER) where the currently open
  procedure ends (i.e. semicolon). Used for outline and folding ranges.
- `ANSWER_VarModified` (17): No arguments. The last syntax element was a
  variable name that is modified (e.g. by `:=` symbol after it).
- `ANSWER_RecordStart` (18): No arguments. last syntax element was a keyword
  that starts a record.
- `ANSWER_RecordEnd` (19): No arguments. Last syntax element was a keyword that
  ends a record. Used for outline and folding ranges.
- `ANSWER_NameExported` (20): Last syntax element was a `*` which was used to
  export the previous syntax element.
- `ANSWER_ImportAlias` (21): No arguments. Last syntax element which was
  reported as a module import was actually an import alias, next syntax element
  will be the module import instead.
- `ANSWER_ProcParamStart` (22): Position (INTEGER) of an opening parenesthis
  that contains procedure parameters (used for context sensitive procedure
  signature help).
- `ANSWER_CallParamStart` (23): Position (INTEGER) of an opening parenthesis
  that contains the parameters of a procedure invocation (for signature help).
- `ANSWER_ParamNext` (24): Position (INTEGER) of a comma that starts the next
  parameter
- `ANSWER_ParamEnd` (25): Position (INTEGER) of the end of parameters
- `ANSWER_ForwardPointer` (26): No arguments. Last syntax element was a forward
  pointer that needs fixup once it is declared.
- `ANSWER_ForwardPointerFixup` (27): Position (INTEGER) of pointer end, and
  position (INTEGER) of pointer target end. Used to fix up the forward pointer.
- `ANSWER_DefinitionRepeat` (28): Last syntax element was a reference to a
  definition, that should not mark it as being used, but instead is only
  repeated due to syntax requirements (after an `END` keyword).
- `ANSWER_DefinitionUsed` (29): Last syntax element was a definition that should
  be considered to be used, even if there is no export or reference assigned to
  it.
- `ANSWER_DeclarationBlockStart` (30): Position (INTEGER) where a declaration
  block starts. A declaration block starts with `VAR`, `TYPE`, or `CONST`
  keyword and goes to the next such keyword or `BEGIN`.
- `ANSWER_DeclarationBlockEnd` (31): Position (INTEGER) where the declaration
  block ends.
- `ANSWER_DefinitionListStart` (32): Position (INTEGER) where a definition list
  starts. A definition list is a list of identifiers that are defined at that
  point and have a common type/value
- `ANSWER_DefinitionListValue` (33): Position (INTEGER) where the type or value
  of that definition list starts
- `ANSWER_DefinitionListEnd` (34): Position (INTEGER) where the definition list
  ends
- `ANSWER_SymbolFileIndex` (35): Symbol file index (INTEGER), Module name
  (String, for re-exports), Offset of end of syntax element (INTEGER). Denotes
  that a symbol has been exported to the symbol file and may be referenced via
  the symbol file index from there.

### Syntax Element format

A syntax element is part of the source code that has certain syntax properties
(highlighting, definition, reference).

Each syntax element consists of the following arguments:
- INTEGER: Start position
- INTEGER: End position
- BYTE: Type (one of `SynOperator` (1), `SynType`, `SynKeyword`, `SynString`,
  `SynComment`, `SynConstant`, `SynUndefined`, `SynModule`, `SynVariable`,
  `SynParameter`, `SynRecordField`, or `SynProcedure` (12))
- INTEGER: Definition end position
- STRING: Definition module name (omitted if definition end position is -1).

In case the definition end position and definition module name is the same as
the end position and current module name, this syntax element is the definition.
Otherwise this syntax element is a reference to the definition mentioned. A
negative definition end position (strictly less than -1) is a symbol file index,
which is mapped by the `ANSWER_SymbolFileIndex` response packet when the
definition module name is/was parsed.

AutoComplete
------------

### Request

- BYTE: `INST_AutoComplete` (101)
- INTEGER: Length of the file prefix
- Content of the file prefix

### Response packets

- `STATUS_OK` (0): No arguments, end of response, everything fine
- `STATUS_Invalid` (1): No arguments, end of response, something went wrong
- `ANSWER_Completion` (80): Syntax element constant (BYTE) and value (STRING) of
  a possible completion value.

ReFormat
--------

The input file is divided into formatting tokens. Everything outside a
formatting token needs to be whitespace. The token category describe what kind
of white space should/may appear before or after the token. A category is a
two-digit decimal integer, where each decimal digit has its own meaning:

- `x0`: No whitespace after token requested
- `x1`: Single whitespalce after token requested
- `x9`: Either no or single whitespace after token is acceptable
- `0x`: No whitespace before token requested
- `1x`: Single whitespace before token requested
- `2x`: Line break before token requested
- `3x`: Line break and empty line before token requested
- `9x`: Either no or single white space before token is acceptable.

In case two adjacent tokens give different rules for the same white space
between them, the token after the white space takes precedence.

### Request

- BYTE: `INST_ReFormat` (102)
- INTEGER: Length of the file prefix
- Content of the file prefix

### Response packets

- `STATUS_OK` (0): No arguments, end of response, everything fine
- `STATUS_Invalid` (1): No arguments, end of response, something went wrong
- `ANSWER_FormatToken` (90): Start position (INTEGER), end position (INTEGER),
  and category (BYTE) of a formatting token.
- `ANSWER_FormatTokenUpdate` (91): Change category (BYTE) of last token. Used
  when the token (like `*`) has a category assigned by the lexer, but the
  category gets overwritten by the parser (e.g. module export instead of
  multiplication).
- `ANSWER_IndentNextLine` (92): The line after the last token needs an
  indentation level higher than the current indentation level.
- `ANSWER_OutdentThisLine` (93): In case the token is the first one of the line,
  this line needs an indentation level lower than the current indentation level.
  In case the token is in the middle of a line, apply the indentation to the
  next line instead.

SwitchEmbeddedMode
------------------

### Request

- BYTE: `INST_SwitchEmbeddedMode` (103)

### Response

No response.

Exit
----

### Request

- BYTE: `INST_Exit` (104)

### Response

Communication stream is closed.
