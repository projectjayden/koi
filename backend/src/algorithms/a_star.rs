use std::collections::BinaryHeap;

struct cell {
    i: f32,
    j: f32,
    f: f32, // addition of g and h's cost
    g: f32, // parent to original pos
    h: f32, // goal to parent
    pointer: cell,
}

impl cell {
    fn location(self: &Self, i_coor: f32, j_coor: f32){
        self.i = i_coor;
        self.j = j_coor;
    }
    fn calcG(self: &Self, startingPos: cell) -> f32 {
        let di = (startingPos.i - self.i).abs();
        let dj = (startingPos.j - self.j).abs();
        let d = 1; // length of each cell
        let d_2 = 2.sqrt(); // length of each diagonal to corner cell
        let distance = d * (dx + dy) + (d_2 - 2 * d) * min(di, dj);
        
        self.g = distance;
        distance
    }
    fn calcH(self: &Self, goalPoint: cell) -> f32 {
        let di = (startingPos.i - self.i).abs();
        let dj = (startingPos.j - self.j).abs();
        let d = 1; // length of each cell
        let d_2 = 2.sqrt(); // length of each diagonal to corner cell
        let distance = d * (dx + dy) + (d_2 - 2 * d) * min(di, dj);
        
        self.h = distance;
        distance
    }
    fn recalcF(self: &Self) -> f32 {
        if self.f == self.g + self.h {return} else {self.f = self.g + self.h};

        self.f
    }
    fn pointToDiffCell(self: &Self, pointingToThisCell: cell){
        self.pointer = cell;
    }
}

fn isValid(node: cell, grid: Vec<Vec<cell>>) -> bool {
    node.i >= 0 && node.j < grid.len() && node.i >= 0 && node.j < grid[0].len()
}

fn isDestination(destinationCell: cell, currentCell: cell) -> bool {
    destinationCell.i == currentCell.i && destinationCell.j == currentCell.j
}

fn a_star(startingNode: cell, endingNode: cell, grid: Vec<Vec<cell>>){
    let openList: Vec<cell> = vec![];
    let closedList: Vec<cell> = vec![];
    let current: cell;

    if !(isValid(startingNode) && isValid(endingNode)) {
        return
    }

    if openList.is_empty() {
        openList.push(startingNode);
    }

    if isDestination(current, endingNode) {
        return
    }
}