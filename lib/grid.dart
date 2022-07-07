import 'dart:math';

import 'package:flutter/material.dart';
import 'package:self_avoiding_walker/cell.dart';

class Grid extends StatefulWidget {
  const Grid({Key? key}) : super(key: key);

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  int dimension = 8;
  double cellSize = 60;
  List walked = [];
  List grid = [];
  Duration delay = const Duration(milliseconds: 10);

  List detail = [];

  String replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) +
        newChar +
        oldString.substring(index + 1);
  }

  fillGrid() async {
    grid = [];
    for (int i = 0; i < dimension; i++) {
      for (int j = 0; j < dimension; j++) {
        if (grid.length <= i) {
          grid.add([]);
        }
        int neighbour = 0;
        if (i != 0) {
          neighbour++;
        }
        if (j != 0) {
          neighbour++;
        }
        if (i != dimension - 1) {
          neighbour++;
        }
        if (j != dimension - 1) {
          neighbour++;
        }
        grid[i].add(Cell(
            i,
            j,
            cellSize,
            false,
            "99",
            ["decreaseI", "increaseI", "decreaseJ", "increaseJ"],
            walked.length,
            neighbour));
        setState(() {});
        await Future.delayed(const Duration(microseconds: 100));
      }
    }
  }

  bestPos() async {
    for (int i = 0; i < dimension; i++) {
      for (int j = 0; j < dimension; j++) {
        walked = [];
        await fillGrid();
        Stopwatch stopwatch = Stopwatch()..start();
        await walk(i, j);
        stopwatch.stop();
        detail.add("Starting from $i,$j completed in ${stopwatch.elapsed}");
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      }
    }
  }

  findBestChoice(i, j, options) {
    Map bestChoice = {"i": 0, "j": 0, "neighbours": 9, "index": 9};
    for (int k = 0; k < options.length; k++) {
      switch (options[k]) {
        case "decreaseI":
          if (checkvalidwalk(i - 1, j)) {
            if (grid[i - 1][j].neighbours < bestChoice["neighbours"]) {
              bestChoice = {
                "i": i - 1,
                "j": j,
                "neighbours": grid[i - 1][j].neighbours,
                "index": k
              };
            }
          }
          break;
        case "increaseI":
          if (checkvalidwalk(i + 1, j)) {
            if (grid[i + 1][j].neighbours < bestChoice["neighbours"]) {
              bestChoice = {
                "i": i + 1,
                "j": j,
                "neighbours": grid[i + 1][j].neighbours,
                "index": k
              };
            }
          }
          break;
        case "decreaseJ":
          if (checkvalidwalk(i, j - 1)) {
            if (grid[i][j - 1].neighbours < bestChoice["neighbours"]) {
              bestChoice = {
                "i": i,
                "j": j - 1,
                "neighbours": grid[i][j - 1].neighbours,
                "index": k
              };
            }
          }
          break;
        case "increaseJ":
          if (checkvalidwalk(i, j + 1)) {
            if (grid[i][j + 1].neighbours < bestChoice["neighbours"]) {
              bestChoice = {
                "i": i,
                "j": j + 1,
                "neighbours": grid[i][j + 1].neighbours,
                "index": k
              };
            }
          }
          break;
      }
    }
    if (bestChoice["neighbours"] == 9) {
      return false;
    } else {
      return bestChoice;
    }
  }

  checkvalidwalk(i, j) {
    if (i < 0 || i >= dimension || j < 0 || j >= dimension) {
      return false;
    }
    if (grid[i][j].walked) {
      return false;
    }
    return true;
  }

  updateNeighboursMinus(i, j) {
    if (i != 0) {
      grid[i - 1][j].neighbours--;
    }
    if (j != 0) {
      grid[i][j - 1].neighbours--;
    }
    if (i != dimension - 1) {
      grid[i + 1][j].neighbours--;
    }
    if (j != dimension - 1) {
      grid[i][j + 1].neighbours--;
    }
  }

  updateNeighboursPlus(i, j) {
    if (i != 0) {
      grid[i - 1][j].neighbours++;
    }
    if (j != 0) {
      grid[i][j - 1].neighbours++;
    }
    if (i != dimension - 1) {
      grid[i + 1][j].neighbours++;
    }
    if (j != dimension - 1) {
      grid[i][j + 1].neighbours++;
    }
  }

  walk(i, j) async {
    grid[i][j].walked = true;
    walked.add({"i": i, "j": j});
    grid[i][j].index = walked.length;
    grid[i][j].order = "00";
    updateNeighboursMinus(i, j);
    setState(() {});
    i = walked.last["i"] ?? 0;
    j = walked.last["j"] ?? 0;
    while (walked.length != dimension * dimension) {
      bool valid = false;
      while (!valid) {
        List options = grid[i][j].options;
        while (options.isEmpty) {
          grid[i][j].walked = false;
          updateNeighboursPlus(i, j);
          grid[i][j].options = [
            "decreaseI",
            "increaseI",
            "decreaseJ",
            "increaseJ"
          ];
          grid[i][j].order = "99";
          walked.removeLast();
          if (walked.isEmpty) {
            print("No Path Found");
            return;
          }
          i = walked.last["i"] ?? 0;
          j = walked.last["j"] ?? 0;
          options = grid[i][j].options;
          setState(() {});
          await Future.delayed(delay);
        }
        var bestChoice = findBestChoice(i, j, options);
        if (bestChoice != false) {
          int direction = bestChoice["neighbours"] == 1
              ? bestChoice["index"]
              : Random().nextInt(options.length);
          int? newi;
          int? newj;
          switch (options[direction]) {
            case "decreaseI":
              newi = i - 1;
              break;
            case "increaseI":
              newi = i + 1;
              break;
            case "decreaseJ":
              newj = j - 1;
              break;
            case "increaseJ":
              newj = j + 1;
              break;
          }
          valid = checkvalidwalk(newi ?? i, newj ?? j);
          if (!valid) {
            options.removeAt(direction);
            if (options.isEmpty) {
              await Future.delayed(delay);

              grid[i][j].walked = false;
              updateNeighboursPlus(i, j);

              grid[i][j].options = [
                "decreaseI",
                "increaseI",
                "decreaseJ",
                "increaseJ"
              ];
              grid[i][j].order = "99";
              walked.removeLast();
              i = walked.last["i"] ?? 0;
              j = walked.last["j"] ?? 0;
              setState(() {});
            }
          } else {
            String choosenOption = grid[i][j].options[direction];
            switch (choosenOption) {
              case "decreaseI":
                //new beg
                grid[newi ?? i][newj ?? j].order =
                    replaceCharAt(grid[newi ?? i][newj ?? j].order, 0, "2");
                //pre end
                grid[i][j].order = replaceCharAt(grid[i][j].order, 1, "0");
                break;
              case "increaseI":
                grid[newi ?? i][newj ?? j].order =
                    replaceCharAt(grid[newi ?? i][newj ?? j].order, 0, "0");
                grid[i][j].order = replaceCharAt(grid[i][j].order, 1, "2");
                break;
              case "decreaseJ":
                grid[newi ?? i][newj ?? j].order =
                    replaceCharAt(grid[newi ?? i][newj ?? j].order, 0, "1");
                grid[i][j].order = replaceCharAt(grid[i][j].order, 1, "3");
                break;
              case "increaseJ":
                grid[newi ?? i][newj ?? j].order =
                    replaceCharAt(grid[newi ?? i][newj ?? j].order, 0, "3");
                grid[i][j].order = replaceCharAt(grid[i][j].order, 1, "1");
                break;
            }
            List temp = grid[i][j].options;
            temp.removeAt(direction);
            grid[i][j].options = temp;

            i = newi ?? i;
            j = newj ?? j;
          }
        } else {
          grid[i][j].walked = false;
          updateNeighboursPlus(i, j);
          grid[i][j].options = [
            "decreaseI",
            "increaseI",
            "decreaseJ",
            "increaseJ"
          ];
          grid[i][j].order = "99";
          walked.removeLast();
          if (walked.isEmpty) {
            print("No Path Found");
            return;
          }
          i = walked.last["i"] ?? 0;
          j = walked.last["j"] ?? 0;
          options = grid[i][j].options;
          setState(() {});
          await Future.delayed(delay);
        }
      }
      grid[i][j].walked = true;
      walked.add({"i": i, "j": j});
      grid[i][j].index = walked.length;
      updateNeighboursMinus(i, j);
      if (walked.length == dimension * dimension) {
        grid[i][j].order = replaceCharAt(
            grid[i][j].order,
            1,
            grid[i][j].order[0] == 0
                ? "2"
                : grid[i][j].order[0] == 1
                    ? "3"
                    : grid[i][j].order[0] == 2
                        ? "0"
                        : "1");
      }
      setState(() {});
      await Future.delayed(delay);
    }
    setState(() {});
  }

  @override
  void initState() {
    // bestPos();
    fillGrid();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all()),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < grid.length; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int j = 0; j < grid[i].length; j++)
                      SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Stack(children: [
                          SizedBox(
                              width: cellSize,
                              height: cellSize,
                              // decoration: BoxDecoration(
                              //     color: Colors.white, border: Border.all()),

                              child: grid[i][j].order == "00"
                                  ? Image.asset(
                                      "assets/00.png",
                                      fit: BoxFit.cover,
                                    )
                                  : grid[i][j].order == "11"
                                      ? Image.asset(
                                          "assets/11.png",
                                          fit: BoxFit.cover,
                                        )
                                      : grid[i][j].order == "22"
                                          ? Image.asset(
                                              "assets/22.png",
                                              fit: BoxFit.cover,
                                            )
                                          : grid[i][j].order == "33"
                                              ? Image.asset(
                                                  "assets/33.png",
                                                  fit: BoxFit.cover,
                                                )
                                              : grid[i][j].order == "01" ||
                                                      grid[i][j].order == "10"
                                                  ? Image.asset(
                                                      "assets/01or10.png",
                                                      fit: BoxFit.cover,
                                                    )
                                                  : grid[i][j].order == "02" ||
                                                          grid[i][j].order ==
                                                              "20"
                                                      ? Image.asset(
                                                          "assets/02or20.png",
                                                          fit: BoxFit.cover,
                                                        )
                                                      : grid[i][j].order ==
                                                                  "03" ||
                                                              grid[i][j]
                                                                      .order ==
                                                                  "30"
                                                          ? Image.asset(
                                                              "assets/03or30.png",
                                                              fit: BoxFit.cover,
                                                            )
                                                          : grid[i][j].order ==
                                                                      "12" ||
                                                                  grid[i][j]
                                                                          .order ==
                                                                      "21"
                                                              ? Image.asset(
                                                                  "assets/12or21.png",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                )
                                                              : grid[i][j].order ==
                                                                          "13" ||
                                                                      grid[i][j]
                                                                              .order ==
                                                                          "31"
                                                                  ? Image.asset(
                                                                      "assets/13or31.png",
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    )
                                                                  : grid[i][j].order ==
                                                                              "23" ||
                                                                          grid[i][j].order ==
                                                                              "32"
                                                                      ? Image.asset(
                                                                          "assets/23or32.png",
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        )
                                                                      : Image.asset(
                                                                          "assets/99.png",
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        )),
                          Center(
                            child: Container(
                              width: dimension / 4,
                              height: dimension / 4,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.black),
                            ),
                          ),

                          // Column(children: [
                          //   Text(
                          //     grid[i][j].neighbours.toString(),
                          //     style: TextStyle(color: Colors.black),
                          //   ),
                          //    Text(
                          //      grid[i][j].index.toString(),
                          //      style: TextStyle(color: Colors.black),
                          //    )
                          // ])
                        ]),
                      )
                  ],
                ),

              GestureDetector(
                onTap: () {
                  walk(0, 0);
                },
                child: const Icon(Icons.play_arrow),
              ),
              GestureDetector(
                onTap: () {
                  fillGrid();
                  walked = [];
                },
                child: const Icon(Icons.cleaning_services_rounded),
              )

              // for (int i = 0; i < detail.length; i++) Text(detail[i]),
            ],
          ),
        ),
      ),
    );
  }
}
