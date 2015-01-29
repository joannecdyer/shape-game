//
//  Board.swift
//  ShapeGame
//
//  Created by Joanne Dyer on 1/13/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation

class Board {
    let numberOfRows, numberOfColumns: Int
    var boardLayout: [Piece?]
    var listener: BoardListener?
    
    init(numberOfRows: Int, numberOfColumns: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColumns = numberOfColumns
        boardLayout = [Piece?](count: numberOfRows*numberOfColumns, repeatedValue: nil)
    }
    
    func fillBoard() {
        for row in 1...numberOfRows {
            for column in 1...numberOfColumns {
                let position = BoardPosition(row: row, column: column)
                let newPiece = Piece.createNewPiece()
                setPieceAtPosition(position, newPiece: newPiece)
                listener?.pieceCreatedAtPosition(position, piece: newPiece, dropAmount: 0)
            }
        }
    }
    
    func canCombinePieceAtStartPositionIntoPieceAtEndPosition(#startPosition: BoardPosition, endPosition: BoardPosition) -> Bool {
        //end position must be adjacent to start. We do not have to worry about being given illegal row or column numbers, this is handled by BoardPosition.
        if (startPosition.row == endPosition.row &&
            abs(startPosition.column - endPosition.column) == 1) ||
            (startPosition.column == endPosition.column &&
            abs(startPosition.row - endPosition.row) == 1) {
            let removedPiece = getPieceAtPosition(startPosition)
            let remainingPiece = getPieceAtPosition(endPosition)
            return remainingPiece.canBeCombinedWithPiece(removedPiece)
        }
        return false
    }
    
    func combinePieceAtStartPositionIntoPieceAtEndPosition(#startPosition: BoardPosition, endPosition: BoardPosition) {
        //only continue if the pieces can be combined, and hence the move is legal.
        assert(canCombinePieceAtStartPositionIntoPieceAtEndPosition(startPosition: startPosition, endPosition: endPosition), "This move is illegal, call canCombinePieceAtStartPositionIntoPieceAtEndPosition to check if a move is possible first.")
        
        let removedPiece = getPieceAtPosition(startPosition)
        let pieceToBeAltered = getPieceAtPosition(endPosition)
        
        //note no pieces are actually moved though there may be a graphic showing movement.
        let alteredPiece = pieceToBeAltered.getResultWhencombinedWithPiece(removedPiece)
        setPieceAtPosition(endPosition, newPiece: alteredPiece)
        listener?.pieceMovedAndNewPieceCreated(oldPosition: startPosition, newPosition: endPosition, newPiece: alteredPiece)
        
        //after the pieces are combined the location of the removed piece will be empty.
        var emptyPositions = [startPosition]
        
        adjustForRemovedPiecesAtPositions(emptyPositions)
    }
    
    private func getPieceAtPosition(position: BoardPosition) -> Piece {
        let arrayIndex = (position.row - 1)*numberOfColumns + (position.column - 1)
        return boardLayout[arrayIndex]!
    }
    
    private func setPieceAtPosition(position: BoardPosition, newPiece: Piece) {
        let arrayIndex = (position.row - 1)*numberOfColumns + (position.column - 1)
        boardLayout[arrayIndex] = newPiece
    }
    
    //it is currently only possible based on the game mechanics to have one position emptied at once, however I have left this function capable of handling 2 removals at once in case the mechanics change again.
    private func adjustForRemovedPiecesAtPositions(emptyPositions: [BoardPosition]) {
        //array must contain one or two positions
        assert(emptyPositions.count == 1 || emptyPositions.count == 2, "the empty positions array should only ever contain one or two elements")
        
        //if there are two positions and they are on the same column drop pieces above simultaneously
        if emptyPositions.count == 2 && emptyPositions[0].column == emptyPositions[1].column {
            let lowestRow = min(emptyPositions[0].row, emptyPositions[1].row)
            dropPiecesInColumn(emptyPositions[0].column, lowestNewRow: lowestRow,
                dropAmount: 2)
        } else if emptyPositions.count == 2 {
            dropPiecesInColumn(emptyPositions[0].column, lowestNewRow: emptyPositions[0].row, dropAmount: 1)
            dropPiecesInColumn(emptyPositions[1].column, lowestNewRow: emptyPositions[1].row, dropAmount: 1)
        } else {
            dropPiecesInColumn(emptyPositions[0].column, lowestNewRow: emptyPositions[0].row, dropAmount: 1)
        }
    }
    
    private func dropPiecesInColumn(column: Int, lowestNewRow: Int, dropAmount: Int) {
        for var row = lowestNewRow+dropAmount; row <= numberOfRows; row++ {
            let oldPosition = BoardPosition(row: row, column: column)
            let newPosition = BoardPosition(row: row - dropAmount, column: column)
            let movingPiece = getPieceAtPosition(oldPosition)
            setPieceAtPosition(newPosition, newPiece: movingPiece)
            listener?.pieceMoved(oldPosition: oldPosition, newPosition: newPosition)
        }
        
        //create new pieces for the now empty spots at the top.
        for rowsFromTop in 0...(dropAmount-1) {
            let emptyPosition = BoardPosition(row: numberOfRows - rowsFromTop, column: column)
            let newPiece = Piece.createNewPiece()
            setPieceAtPosition(emptyPosition, newPiece: newPiece)
            listener?.pieceCreatedAtPosition(emptyPosition, piece: newPiece, dropAmount: dropAmount)
        }
    }
}