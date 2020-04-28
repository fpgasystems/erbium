## Binary Specifications

Binary communication between SW and HW is constructed respecting the constraints mainly declared in definition.h and engine_pkg.vhd.

### Queries input stream

Each query is 512-bit aligned. Within each query, values are 16-bit aligned, their actual size being 13 bits. The order of the values matter: it must be the same as the one generated for the NFA (i.e., as shown by the generated file dictionnary.csv).
```
|  0  ...  12 |   ....   | 16  ...  28 |   ....   |  32  ...  495 | 496  ...  508 | .... 511 |
|   value 0   | zero-pad |   value 1   | zero-pad |     .....     |    value 31   | zero-pad |
```
Constant | Description | 
----------------------------------|-------------|---
`CFG_ENGINE_NCRITERIA` (22)       | # of criteria
`CFG_CRITERION_VALUE_WIDTH` (13b) | # of bits per criterion value
`CFG_RAW_OPERAND_WIDTH` (16b)     | # of bits for SW/HW communication

##### Encodings
Literal and alphanumeric values are encoded using Dictionary Compression. Numeric values may be either used without encoding (e.g., flight numbers), or encoded for specific criteria (e.g., *Rata Die* encoding for calendar days).
Wildcard (or *empty* values for non-mandatory criteria) are encoded as `0` for performance reasons.

### Result output stream
A single 13-bit value (16-bit aligned) with the encoded result is outputed per query.

### NFA Transitions

From [1] 4.2 Memory Unit: Storing the NFA:
> To store the NFA in memory, we take advantage of the fact that the NFA is organised by levels, with each level corresponding to one criterion. The graph data is organised in such a manner that all the information is contained within the transitions, so they are the single element required to be stored in the memory tables. Within each table, transitions are stored in a breadth-first order so the ones leaving the same state are contiguous in memory. Each row in a table contains the information required for evaluating a transition as part of a path: 
> 1. The *value* (or pair of values, in the case of ranges) to be matched against the query;
> 1. A *pointer* to the row in the table of the next level where the transition leads; and
> 1. A *last-transition* flag indicating the end of the current set of transitions for that state. 
within the set.

  Field   | Description                        | Size                                 | Offset
----------|------------------------------------|--------------------------------------|:------:
operand A | Criterion value A                  | `CFG_CRITERION_VALUE_WIDTH` (13b)    | 0
operand B | Criterion value B                  | `CFG_CRITERION_VALUE_WIDTH` (13b)    | 16
pointer   | Address pointer to next transition | `CFG_TRANSITION_POINTER_WIDTH` (16b) | 32
Lt        | *last-transition* flag             | (1b)                                 | 48

```
| 0 | ... | 12 |   ....   | 16 | ... | 28 |   ....   | 32 | ... | 47 | 48 | .... | 63 |
|  operand  a  | zero-pad |   operand b   | zero-pad |    pointer    | Lt | zero-pad  |
```
The FPGA engine receives a stream of transitions in the following format: for each NFA level, the first 64 bits consist of the number of transition within that level, followed by the later. Important to notice the zero-paddings, so the beginning of a level-data is always 512-bit aligned.

In the following example, the first NFA level has 2 transitions and the second has 9 transitions:
```
|   0 | .... |  63 |  64 | .... | 127 | 128 | .... | 191 | 192   ...    447 | 448 ...... 511 |
|   level-0-size   |   transition 0   |   transition 1   |           zero-padding            |
|   level-1-size   |   transition 0   |   transition 1   |       ...        |   transition 6 |
|   transition 7   |   transition 8   |                     zero-padding                     |
```