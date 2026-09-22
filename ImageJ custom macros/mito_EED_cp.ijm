// Get all ROIs from ROI Manager
n = roiManager("count");
if (n == 0) {
    exit("No ROIs found in ROI Manager");
}

// Get image stack info
Stack.getDimensions(width, height, channels, slices, frames);
totalSlices = maxOf(slices, frames);

// Get calibration info
getPixelSize(unit, pw, ph);

print("\\Clear");
print("Processing stack with " + totalSlices + " slices");
print("Calibration: 1 pixel = " + pw + " " + unit);

// Arrays to store ROI INDICES (the internal ID 0..n) organized by slice
// We use strings to store lists of indices "1,5,9"
chloroIndicesBySlice = newArray(totalSlices);
mitoIndicesBySlice = newArray(totalSlices);

// Initialize arrays
for (s = 0; s < totalSlices; s++) {
    chloroIndicesBySlice[s] = "";
    mitoIndicesBySlice[s] = "";
}

// 1. CLASSIFICATION STEP
// Loop through every ROI to figure out which slice and color it belongs to
for (i = 0; i < n; i++) {
    roiManager("select", i);
    
    // Get the slice number of this ROI
    currentSlice = getSliceNumber();
    sliceIdx = currentSlice - 1;
    
    // Get color
    color = Roi.getStrokeColor();
    colorName = toLowerCase(color);
    
    // Store the INDEX (i), not the name
    if (indexOf(colorName, "green") >= 0) {
        if (chloroIndicesBySlice[sliceIdx] == "") {
            chloroIndicesBySlice[sliceIdx] = "" + i;
        } else {
            chloroIndicesBySlice[sliceIdx] = chloroIndicesBySlice[sliceIdx] + "," + i;
        }
    } else if (indexOf(colorName, "red") >= 0) {
        if (mitoIndicesBySlice[sliceIdx] == "") {
            mitoIndicesBySlice[sliceIdx] = "" + i;
        } else {
            mitoIndicesBySlice[sliceIdx] = mitoIndicesBySlice[sliceIdx] + "," + i;
        }
    }
}

// Create results table
title = "Mito-Chloroplast Distances";
if (isOpen(title)) {
    selectWindow(title);
    run("Close");
}
Table.create(title);
rowCount = 0;

// Variables for coordinates
var mitoX, mitoY, chloroX, chloroY; 

// 2. CALCULATION STEP
for (s = 1; s <= totalSlices; s++) {
    chloroStr = chloroIndicesBySlice[s-1];
    mitoStr = mitoIndicesBySlice[s-1];
    
    if (chloroStr == "" || mitoStr == "") {
        continue;
    }
    
    // Split the strings back into arrays of indices
    cIndices = split(chloroStr, ",");
    mIndices = split(mitoStr, ",");
    
    print("Slice " + s + ": Analyzing " + mIndices.length + " mitochondria against " + cIndices.length + " chloroplasts.");
    
    // For each mitochondrion on this slice
    for (m = 0; m < mIndices.length; m++) {
        // Get the ROI Manager Index
        mitoIdx = parseInt(mIndices[m]);
        
        // Select the specific Mito
        roiManager("select", mitoIdx);
        mitoName = Roi.getName(); // Get label for the table
        
        // Get Bounding Box & Coordinates (Absolute)
        getSelectionBounds(mx, my, mw, mh);
        getSelectionCoordinates(mitoX, mitoY);
        mitoNumPoints = lengthOf(mitoX);
        
        minGlobalEED = 999999;
        nearestEdgeNeighborName = "None";
        
        // Compare against EVERY Chloroplast on this slice
        for (c = 0; c < cIndices.length; c++) {
            chloroIdx = parseInt(cIndices[c]);
            roiManager("select", chloroIdx);
            chloroName = Roi.getName(); // Get label for the table
            
            // --- OPTIMIZATION: BOUNDING BOX CHECK ---
            getSelectionBounds(cx, cy, cw, ch);
            
            // Calculate distance between the bounding boxes first
            dx_rect = 0;
            dy_rect = 0;
            
            if (cx > mx + mw) dx_rect = cx - (mx + mw);
            else if (mx > cx + cw) dx_rect = mx - (cx + cw);
            
            if (cy > my + mh) dy_rect = cy - (my + mh);
            else if (my > cy + ch) dy_rect = my - (cy + ch);
            
            approxDist = sqrt(dx_rect*dx_rect + dy_rect*dy_rect);
            approxDistCal = approxDist * pw;
            
            // If the boxes are far apart (e.g., > 2 microns more than our current best), skip
            if (approxDistCal < minGlobalEED + 2.0) {
                
                // --- DETAILED PIXEL CHECK ---
                getSelectionCoordinates(chloroX, chloroY);
                chloroNumPoints = lengthOf(chloroX);
                
                localMinEED = 999999;
                
                for (mp = 0; mp < mitoNumPoints; mp++) {
                    // Ignore composite ROI separators
                    if (mitoX[mp] == -1) continue;
                    
                    curMx = mitoX[mp];
                    curMy = mitoY[mp];
                    
                    for (cp = 0; cp < chloroNumPoints; cp++) {
                        if (chloroX[cp] == -1) continue;
                        
                        curCx = chloroX[cp];
                        curCy = chloroY[cp];
                        
                        // Calc pixel distance
                        dx_px = curMx - curCx;
                        dy_px = curMy - curCy;
                        
                        // Convert to calibrated units
                        dx_cal = dx_px * pw;
                        dy_cal = dy_px * ph;
                        
                        dist = sqrt(dx_cal*dx_cal + dy_cal*dy_cal);
                        
                        if (dist < localMinEED) {
                            localMinEED = dist;
                        }
                    }
                }
                
                // If this chloroplast is closer than the previous best match
                if (localMinEED < minGlobalEED) {
                    minGlobalEED = localMinEED;
                    nearestEdgeNeighborName = chloroName;
                }
            }
        }
        
        // Populate Table
        Table.set("Slice", rowCount, s);
        Table.set("Mito_Label", rowCount, mitoName);
        Table.set("Nearest_Chloro_Label", rowCount, nearestEdgeNeighborName);
        Table.set("Edge_Distance_" + unit, rowCount, minGlobalEED);
        rowCount++;
    }
}

Table.update(title);
print("\\Update:Analysis complete!");
roiManager("Show All with labels");
roiManager("deselect");