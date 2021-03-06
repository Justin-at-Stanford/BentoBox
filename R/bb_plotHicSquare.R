#' Plot a Hi-C interaction matrix in a square format
#'
#' @usage
#' bb_plotHicSquare(hicData, chrom)
#' bb_plotHicSquare(hicData, chrom, x, y, width, height,
#'                  just = c("left", "top"),
#'                  default.units = "inches")
#'
#' @param hicData Path to .hic file as a string or a 3-column dataframe of interaction counts in sparse upper triangular format.
#' @param resolution A numeric specifying the width in basepairs of each pixel. For hic files, "auto" will attempt to choose a resolution based on the size of the region. For
#' dataframes, "auto" will attempt to detect the resolution the dataframe contains.
#' @param zrange A numeric vector of length 2 specifying the range of interaction scores to plot, where extreme values will be set to the max or min.
#' @param norm Character value specifying hic data normalization method, if giving .hic file. This value must be found in the .hic file. Default value is \code{norm = "KR"}.
#' @param matrix Character value indicating the type of matrix to output. Default value is \code{matrix = "observed"}. Options are:
#' \itemize{
#' \item{\code{"observed"}: }{Observed counts.}
#' \item{\code{"oe"}: }{Observed/expected counts.}
#' }
#' @param chrom Chromosome of region to be plotted, as a string.
#' @param chromstart Integer start position on chromosome to be plotted.
#' @param chromend Integer end position on chromosome to be plotted.
#' @param altchrom Alternate chromosome for off-diagonal plotting or interchromosomal plotting, as a string.
#' @param altchromstart Alternate chromosome integer start position for off-diagonal plotting or interchromosomal plotting.
#' @param altchromend Alternate chromosome integer end position for off-diagonal plotting or interchromosomal plotting.
#' @param assembly Default genome assembly as a string or a \link[BentoBox]{bb_assembly} object. Default value is \code{assembly = "hg19"}.
#' @param palette A function describing the color palette to use for representing scale of interaction scores. Default value is \code{palette = colorRampPalette(c("white", "dark red"))}.
#' @param half A character value indicating which diagonal regions to plot. For intrachromosomal plotting, options are \code{"both"}, \code{"top"}, or \code{"bottom"}. For off-diagonal or interchromosomal plotting, options are \code{"top"} or \code{"bottom"}. Default value is \code{half = "both"}.
#' \itemize{
#' \item{\code{"both"}: }{Both diagonal halves.}
#' \item{\code{"top"}: }{Half above the diagonal.}
#' \item{\code{"bottom"}: }{Half below the diagonal.}
#' }
#' @param x A numeric or unit object specifying square Hi-C plot x-location.
#' @param y A numeric or unit object specifying square Hi-C plot y-location.
#' @param width A numeric or unit object specifying square Hi-C plot width.
#' @param height A numeric or unit object specifying square Hi-C plot height.
#' @param just Justification of square Hi-C plot relative to its (x, y) location. If there are two values, the first value specifies horizontal justification and the second value specifies vertical justification.
#' Possible string values are: \code{"left"}, \code{"right"}, \code{"centre"}, \code{"center"}, \code{"bottom"}, and \code{"top"}. Default value is \code{just = c("left", "top")}.
#' @param default.units A string indicating the default units to use if \code{x}, \code{y}, \code{width}, or \code{height} are only given as numerics. Default value is \code{default.units = "inches"}.
#' @param draw A logical value indicating whether graphics output should be produced. Default value is \code{draw = TRUE}.
#' @param params An optional \link[BentoBox]{bb_assembly} object containing relevant function parameters.
#'
#' @return Returns a \code{bb_hicSquare} object containing relevant genomic region, Hi-C data, placement, and \link[grid]{grob} information.
#'
#' @examples
#' ## Load Hi-C data
#' data("bb_hicData")
#'
#' ## Plot upper diagonal of square Hi-C plot filling up entire graphic device
#' bb_plotHicSquare(hicData = bb_hicData, resolution = 10000, zrange = c(0, 70),
#'                  chrom = "chr21", chromstart = 28000000, chromend = 30300000, half = "top")
#'
#' ## Plot and place both halves of square Hi-C plot on a BentoBox page
#' bb_pageCreate(width = 3, height = 3, default.units = "inches", xgrid = 0, ygrid = 0)
#' bb_plotHicSquare(hicData = bb_hicData, resolution = 10000, zrange = c(0, 70),
#'                  chrom = "chr21", chromstart = 28000000, chromend = 30300000,
#'                  x = 0.5, y = 0.5, width = 2, height = 2, just = c("left", "top"), default.units = "inches")
#'
#' @seealso \link[BentoBox]{bb_readHic}
#'
#' @export
bb_plotHicSquare <- function(hicData, resolution = "auto", zrange = NULL, norm = "KR", matrix = "observed", chrom, chromstart = NULL, chromend = NULL, altchrom = NULL,
                             altchromstart = NULL, altchromend = NULL, assembly = "hg19", palette = colorRampPalette(c("white", "dark red")),
                             half = "both", x = NULL, y = NULL, width = NULL, height = NULL, just = c("left", "top"), default.units = "inches",
                             draw = TRUE, params = NULL){

  # ======================================================================================================================================================================================
  # FUNCTIONS
  # ======================================================================================================================================================================================

  ## Define a function that catches errors for bb_plothic
  errorcheck_bb_plothic <- function(hic, hic_plot, norm){

    ###### hic/norm #####

    ## if it's a dataframe or datatable, it needs to be properly formatted
    if ("data.frame" %in% class(hic) && ncol(hic) != 3){

      stop("Invalid dataframe format.  Input a dataframe with 3 columns: chrA, chrB, counts.", call. = FALSE)

    }

    if (!"data.frame" %in% class(hic)){

      ## if it's a file path, it needs to be a .hic file
      if (file_ext(hic) != "hic"){

        stop("Invalid input. File must have a \".hic\" extension", call. = FALSE)

      }

      ## if it's a file path, it needs to exist
      if (!file.exists(hic)){

        stop(paste("File", hic, "does not exist."), call. = FALSE)

      }

      ## if it's a valid .hic file, it needs to have a valid norm parameter
      if (is.null(norm)){

        stop("If providing .hic file, please specify \'norm\'.", call. = FALSE)

      }

    }

    ###### chrom/chromstart/chromend/altchrom/altchromstart/altchromend #####

    ## Can't have only one NULL chromstart or chromend
    if ((is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)) | (is.null(hic_plot$chromend) & !is.null(hic_plot$chromstart))){

      stop("Cannot have one \'NULL\' \'chromstart\' or \'chromend\'.", call. = FALSE)

    }

    if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){
      ## Chromstart should be smaller than chromend
      if (hic_plot$chromstart > hic_plot$chromend){

        stop("\'chromstart\' should not be larger than \'chromend\'.", call. = FALSE)

      }

    }

    ## Even though straw technically works without "chr" for hg19, will not accept for consistency purposes
    if (hic_plot$assembly$Genome == "hg19"){

      if (grepl("chr", hic_plot$chrom) == FALSE){

        stop(paste(paste0("'",hic_plot$chrom, "'"), "is an invalid input for an hg19 chromsome. Please specify chromosome as", paste0("'chr", hic_plot$chrom, "'.")), call. = FALSE)
      }

    }

    if (!is.null(hic_plot$altchrom)){

      ## Can't specify altchrom without a chrom
      if (is.null(hic_plot$chrom)){

        stop("Specified \'altchrom\', but did not give \'chrom\'.", call. = FALSE)

      }
      ## Even though straw technically works without "chr" for hg19, will not accept for consistency purposes
      if (hic_plot$assembly$Genome == "hg19"){

        if (grepl("chr", hic_plot$altchrom) == FALSE){

          stop(paste(paste0("'",hic_plot$altchrom, "'"), "is an invalid input for an hg19 chromsome. Please specify chromosome as", paste0("'chr", hic_plot$altchrom, "'.")), call. = FALSE)
        }

      }


      ## Can't have only one NULL altchromstart or altchromend

      if ((is.null(hic_plot$altchromstart) & !is.null(hic_plot$altchromend)) | (is.null(hic_plot$altchromend) & !is.null(hic_plot$altchromstart))){

        stop("Cannot have one \'NULL\' \'altchromstart\' or \'altchromend\'.", call. = FALSE)

      }

      if (!is.null(hic_plot$altchromstart) & !is.null(hic_plot$altchromend)){

        ## Altchromstart should be smaller than altchromend
        if (hic_plot$altchromstart > hic_plot$altchromend){

          stop("\'altchromstart\' should not be larger than \'altchromend\'.", call. = FALSE)

        }

      }


      if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend) & !is.null(hic_plot$altchromstart) & !is.null(hic_plot$altchromend)){

        ## Check to see if region is square
        if ((hic_plot$chromend - hic_plot$chromstart) != (hic_plot$altchromend - hic_plot$altchromstart)){

          warning("Trying to plot non-square region.", call. = FALSE)

        }
      }

    }

    ###### zrange #####

    ## Ensure properly formatted zrange
    if (!is.null(hic_plot$zrange)){

      ## zrange needs to be a vector
      if (!is.vector(hic_plot$zrange)){

        stop("\'zrange\' must be a vector of length 2.", call. = FALSE)

      }

      ## zrange vector needs to be length 2
      if (length(hic_plot$zrange) != 2){

        stop("\'zrange\' must be a vector of length 2.", call. = FALSE)

      }

      ## zrange vector needs to be numbers
      if (!is.numeric(hic_plot$zrange)){

        stop("\'zrange\' must be a vector of two numbers.", call. = FALSE)

      }

      ## second value should be larger than the first value
      if (hic_plot$zrange[1] >= hic_plot$zrange[2]){

        stop("\'zrange\' must be a vector of two numbers in which the 2nd value is larger than the 1st.", call. = FALSE)

      }

    }


    ###### half/althalf #####

    if (is.null(hic_plot$altchrom)){

      if (!(hic_plot$half %in% c("both", "top", "bottom"))){

        stop("Invalid \'half\'.  Options are \'both\', \top\', or \'bottom\'.", call. = FALSE)

      }

    } else {


      if (!hic_plot$half %in% c("top", "bottom")){

        stop("Invalid \'half\' for off-diagonal and interchromosomal plotting.  Options are \'top\' or \'bottom\'.", call. = FALSE)

      }

    }

  }

  ## Define a function that checks for and gets whole chromosome starts/ends based on an assembly TxDb
  get_wholeChrom <- function(chrom, assembly){

    chromstart <- NULL
    chromend <- NULL

    txdbChecks <- check_loadedPackage(package = assembly$TxDb, message = paste(paste0("`", assembly$TxDb,"`"),
                                                                                        "not loaded. Please install and load to plot full chromosome HiC map."))
    if (txdbChecks == TRUE){

      tx_db <- eval(parse(text = assembly$TxDb))
      assembly_data <- seqlengths(tx_db)

      if (!chrom %in% names(assembly_data)){
        warning(paste("Chromosome", paste0("'", chrom, "'"), "not found in", paste0("`", assembly$TxDb, "`"), "and data for entire chromosome cannot be plotted."), call. = FALSE)
      } else {
        chromstart <- 1
        chromend <- assembly_data[[chrom]]

      }


    }


    return(list(chromstart, chromend))


  }

  ## Define a function to check range of data in dataframe
  check_dataframe <- function(hic, hic_plot){

    if (is.null(hic_plot$altchrom)){

      if (min(hic[,1]) > hic_plot$chromstart | max(hic[,1]) < hic_plot$chromend | min(hic[,2]) > hic_plot$chromstart | max(hic[,2]) < hic_plot$chromend){

        warning("Data is incomplete for the specified range.", call. = FALSE)

      }

    } else {

      if (min(hic[,1]) > hic_plot$chromstart | max(hic[,1]) < hic_plot$chromend | min(hic[,2]) > hic_plot$altchromstart | max(hic[,2]) < hic_plot$altchromend){

        warning("Data is incomplete for the specified range.", call. = FALSE)
      }

    }

  }

  ## Define a function to adjust/detect resolution based on .hic file/dataframe
  adjust_resolution <- function(hic, hic_plot){

    if (!("data.frame" %in% class(hic))){

      if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){

        ## Get range of data and try to pick a resolution to extract from hic file
        dataRange <- hic_plot$chromend - hic_plot$chromstart
        if (dataRange >= 150000000){
          bestRes <- 500000
        } else if (dataRange >= 75000000 & dataRange < 150000000){
          bestRes <- 250000
        } else if (dataRange >= 35000000 & dataRange < 75000000){
          bestRes <- 100000
        } else if (dataRange >= 20000000 & dataRange < 35000000){
          bestRes <- 50000
        } else if (dataRange >= 5000000 & dataRange < 20000000){
          bestRes <- 25000
        } else if (dataRange >= 3000000 & dataRange < 5000000){
          bestRes <- 10000
        } else {
          bestRes <- 5000
        }

        hic_plot$resolution <- as.integer(bestRes)

      }

    } else {

      ## Try to detect resolution from data
      offDiag <- hic[which(hic[,1] != hic[,2]),]
      bpDiffs <- abs(offDiag[,2] - offDiag[,1])
      predRes <- min(bpDiffs)

      hic_plot$resolution <- as.integer(predRes)

    }

    return(hic_plot)
  }

  ## Define a function that reads in hic data for bb_plothic
  read_data <- function(hic, hic_plot, norm, assembly, type){

    ## if .hic file, read in with bb_rhic
    if (!("data.frame" %in% class(hic))){

      if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){

        readchromstart <- hic_plot$chromstart - hic_plot$resolution
        readchromend <- hic_plot$chromend + hic_plot$resolution
        readaltchromstart <- hic_plot$altchromstart - hic_plot$resolution
        readaltchromend <- hic_plot$altchromend + hic_plot$resolution
        hic <- suppressWarnings(bb_readHic(hicFile = hic, chrom = hic_plot$chrom, chromstart = readchromstart, chromend = readchromend,
                                           resolution = hic_plot$resolution, zrange = hic_plot$zrange, norm = norm,
                                           altchrom = hic_plot$altchrom, altchromstart = readaltchromstart,
                                           altchromend = readaltchromend, matrix = type))
      } else {
        hic <- data.frame(matrix(nrow = 0, ncol = 3))
      }



    } else {

      if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){
        message(paste("Read in dataframe.  Assuming \'chrom\' in column1 and \'altchrom\' in column2.", hic_plot$resolution, "BP resolution detected."))
        ## check range of data in dataframe
        check_dataframe(hic = hic, hic_plot = hic_plot)
      } else {
        hic <- data.frame(matrix(nrow = 0, ncol = 3))
      }

    }

    ## Rename columns for later processing
    colnames(hic) <- c("x", "y", "counts")
    hic <- na.omit(hic)

    return(hic)

  }

  ## Define a function that subsets data
  subset_data <- function(hic, hic_plot){

    if (nrow(hic) > 0){

      if (is.null(hic_plot$altchrom)){

        hic <- hic[which(hic[,1] >= hic_plot$chromstart - hic_plot$resolution &
                           hic[,1] <= hic_plot$chromend + hic_plot$resolution &
                           hic[,2] >= hic_plot$chromstart - hic_plot$resolution &
                           hic[,2] <= hic_plot$chromend + hic_plot$resolution),]

      } else {

        if (hic_plot$chrom != hic_plot$altchrom){

          hic <- hic[which(hic[,1] >= hic_plot$chromstart - hic_plot$resolution &
                             hic[,1] <= hic_plot$chromend + hic_plot$resolution &
                             hic[,2] >= hic_plot$altchromstart - hic_plot$resolution &
                             hic[,2] <= hic_plot$altchromend + hic_plot$resolution),]

        }


      }
    }

    return(hic)
  }

  ## Define a function that sets the zrange
  set_zrange <- function(hic, hic_plot){

    ## no zrange, only one value
    if (is.null(hic_plot$zrange) & length(unique(hic$counts)) == 1){

      zrange <- c(unique(hic$counts), unique(hic$counts))
      hic_plot$zrange <- zrange

    }

    ## no zrange, multiple values
    if (is.null(hic_plot$zrange) & length(unique(hic$counts)) > 1){

      zrange <- c(0, max(hic$counts))
      hic_plot$zrange <- zrange

    }

    return(hic_plot)

  }

  ## Define a function that sets viewport xscale and yscale
  vp_scale <- function(hic_plot){

  if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){

    if (is.null(hic_plot$altchrom)){

      xscale <- c(hic_plot$chromstart, hic_plot$chromend)
      yscale <- xscale

    } else {

      if (hic_plot$half == "bottom"){

        xscale <- c(hic_plot$chromstart, hic_plot$chromend)
        yscale <- c(hic_plot$altchromstart, hic_plot$altchromend)

      }

      if (hic_plot$half == "top"){

        xscale <- c(hic_plot$altchromstart, hic_plot$altchromend)
        yscale <- c(hic_plot$chromstart, hic_plot$chromend)

      }


    }

  } else {

    xscale <- c(0, 1)
    yscale <- c(0, 1)


  }

    return(list(xscale, yscale))
  }

  ## Define a function that subsets the hic dataframe into which will be squares and which will be triangles
  hic_shapes <- function(hic, hic_plot, half){

    if (!is.null(hic_plot$altchrom)){

      ## all squares
      squares <- hic
      triangles <- NULL

    } else {

      if (half == "both"){

        ## all squares
        squares <- hic
        triangles <- NULL

      } else if (half == "top"){

        ## squares for top half
        ## triangles for diagonal

        squares <- hic[which(hic[,2] > hic[,1]),]
        triangles <- hic[which(hic[,2] == hic[,1]),]

      } else if (half == "bottom"){

        ## squares for bottom half
        ## triangles for diagonal

        squares <- hic[which(hic[,2] < hic[,1]),]
        triangles <- hic[which(hic[,2] == hic[,1]),]


      }

    }

  return(list(squares, triangles))

  }

  ## Define a function that makes grobs for the hic diagonal
  hic_diagonal <- function(hic, hic_plot, half){

    col <- hic[4]
    x <- as.numeric(hic[1])
    y <- as.numeric(hic[2])

    xleft = x
    xright = x + hic_plot$resolution
    ybottom = y
    ytop = y + hic_plot$resolution

    if (half == "top"){

      hic_triangle <- polygonGrob(x = c(xleft, xleft, xright),
                                  y = c(ybottom, ytop, ytop),
                                  gp = gpar(col = NA, fill = col),
                                  default.units = "native")


    } else if (half == "bottom"){


      hic_triangle <- polygonGrob(x = c(xleft, xright, xright),
                                  y = c(ybottom, ybottom, ytop),
                                  gp = gpar(col = NA, fill = col),
                                  default.units = "native")


      }

    assign("hic_grobs", addGrob(gTree = get("hic_grobs", envir = bbEnv), child = hic_triangle), envir = bbEnv)

  }

  # ======================================================================================================================================================================================
  # PARSE PARAMETERS
  # ======================================================================================================================================================================================

  ## Check which defaults are not overwritten and set to NULL
  if(missing(half)) half <- NULL
  if(missing(resolution)) resolution <- NULL
  if(missing(palette)) palette <- NULL
  if(missing(assembly)) assembly <- NULL
  if(missing(just)) just <- NULL
  if(missing(default.units)) default.units <- NULL
  if(missing(draw)) draw <- NULL
  if(missing(norm)) norm <- NULL
  if(missing(matrix)) matrix <- NULL

  ## Check if hic/chrom arguments are missing (could be in object)
  if(!hasArg(hicData)) hicData <- NULL
  if(!hasArg(chrom)) chrom <- NULL

  ## Compile all parameters into an internal object
  bb_hicInternal <- structure(list(hicData = hicData, chrom = chrom, chromstart = chromstart, chromend = chromend, half = half, resolution = resolution,
                                   zrange = zrange, palette = palette, assembly = assembly, width = width, height = height, x = x, y = y, just = just,
                                   default.units = default.units, draw = draw, altchrom = altchrom, altchromstart = altchromstart, altchromend = altchromend,
                                   norm = norm, matrix = matrix), class = "bb_hicInternal")

  bb_hicInternal <- parseParams(bb_params = params, object_params = bb_hicInternal)

  ## For any defaults that are still NULL, set back to default
  if(is.null(bb_hicInternal$half)) bb_hicInternal$half <- "both"
  if(is.null(bb_hicInternal$resolution)) bb_hicInternal$resolution <- "auto"
  if(is.null(bb_hicInternal$palette)) bb_hicInternal$palette <- colorRampPalette(c("white", "dark red"))
  if(is.null(bb_hicInternal$assembly)) bb_hicInternal$assembly <- "hg19"
  if(is.null(bb_hicInternal$just)) bb_hicInternal$just <- c("left", "top")
  if(is.null(bb_hicInternal$default.units)) bb_hicInternal$default.units <- "inches"
  if(is.null(bb_hicInternal$draw)) bb_hicInternal$draw <- TRUE
  if(is.null(bb_hicInternal$norm)) bb_hicInternal$norm <- "KR"
  if(is.null(bb_hicInternal$matrix)) bb_hicInternal$matrix <- "observed"

  if(is.null(bb_hicInternal$hicData)) stop("argument \"hicData\" is missing, with no default.", call. = FALSE)
  if(is.null(bb_hicInternal$chrom)) stop("argument \"chrom\" is missing, with no default.", call. = FALSE)

  # ======================================================================================================================================================================================
  # INITIALIZE OBJECT
  # ======================================================================================================================================================================================

  hic_plot <- structure(list(chrom = bb_hicInternal$chrom, chromstart = bb_hicInternal$chromstart, chromend = bb_hicInternal$chromend, altchrom = bb_hicInternal$altchrom,
                             altchromstart = bb_hicInternal$altchromstart, altchromend = bb_hicInternal$altchromend, assembly = bb_hicInternal$assembly, resolution = bb_hicInternal$resolution,
                             x = bb_hicInternal$x, y = bb_hicInternal$y, width = bb_hicInternal$width, height = bb_hicInternal$height, just = bb_hicInternal$just, color_palette = NULL, zrange = bb_hicInternal$zrange,
                             half = bb_hicInternal$half, grobs = NULL), class = "bb_hicSquare")
  attr(x = hic_plot, which = "plotted") <- bb_hicInternal$draw

  # ======================================================================================================================================================================================
  # PARSE ASSEMBLY
  # ======================================================================================================================================================================================

  hic_plot$assembly <- parse_bbAssembly(assembly = hic_plot$assembly)

  # ======================================================================================================================================================================================
  # CATCH ERRORS
  # ======================================================================================================================================================================================

  check_placement(object = hic_plot)
  errorcheck_bb_plothic(hic = bb_hicInternal$hicData, hic_plot = hic_plot, norm = bb_hicInternal$norm)

  # ======================================================================================================================================================================================
  # PARSE UNITS
  # ======================================================================================================================================================================================

  hic_plot <- defaultUnits(object = hic_plot, default.units = bb_hicInternal$default.units)

  # ======================================================================================================================================================================================
  # WHOLE CHROM INFORMATION
  # ======================================================================================================================================================================================

  if (is.null(hic_plot$chromstart) & is.null(hic_plot$chromend)){

    chromData <- get_wholeChrom(chrom = hic_plot$chrom, assembly = hic_plot$assembly)
    hic_plot$chromstart <- chromData[[1]]
    hic_plot$chromend <- chromData[[2]]

  }

  if (!is.null(hic_plot$altchrom)){
    if(is.null(hic_plot$altchromstart) & is.null(hic_plot$altchromend)){
      altchromData <- get_wholeChrom(chrom = hic_plot$altchrom, assembly = hic_plot$assembly)
      hic_plot$altchromstart <- altchromData[[1]]
      hic_plot$altchromend <- altchromData[[2]]
    }

  }

  # ======================================================================================================================================================================================
  # ADJUST RESOLUTION
  # ======================================================================================================================================================================================

  if (hic_plot$resolution == "auto"){
    hic_plot <- adjust_resolution(hic = bb_hicInternal$hicData, hic_plot = hic_plot)
  }

  # ======================================================================================================================================================================================
  # READ IN DATA
  # ======================================================================================================================================================================================

  hic <- read_data(hic = bb_hicInternal$hicData, hic_plot = hic_plot, norm = bb_hicInternal$norm, assembly = hic_plot$assembly, type = bb_hicInternal$matrix)

  # ======================================================================================================================================================================================
  # SUBSET DATA
  # ======================================================================================================================================================================================

  hic <- subset_data(hic = hic, hic_plot = hic_plot)

  # ======================================================================================================================================================================================
  # MAKE SYMMETRIC
  # ======================================================================================================================================================================================

  hicFlip = hic[, c(2, 1, 3)]
  colnames(hicFlip) <- c("x", "y", "counts")
  hic <- unique(rbind(hic, hicFlip))
  colnames(hic) = c("x", "y", "counts")

  # ======================================================================================================================================================================================
  # SET ZRANGE AND SCALE DATA
  # ======================================================================================================================================================================================

  hic_plot <- set_zrange(hic = hic, hic_plot = hic_plot)
  hic$counts[hic$counts <= hic_plot$zrange[1]] <- hic_plot$zrange[1]
  hic$counts[hic$counts >= hic_plot$zrange[2]] <- hic_plot$zrange[2]

  # ======================================================================================================================================================================================
  # CONVERT NUMBERS TO COLORS
  # ======================================================================================================================================================================================

  ## if we don't have an appropriate zrange (even after setting it based on a null zrange), can't scale to colors
  if (!is.null(hic_plot$zrange) & length(unique(hic_plot$zrange)) == 2){

    hic$color <- bb_maptocolors(hic$counts, col = bb_hicInternal$palette, num = 100, range = hic_plot$zrange)
    hic_plot$color_palette <- bb_hicInternal$palette

    }

  # ======================================================================================================================================================================================
  # VIEWPORTS
  # ======================================================================================================================================================================================

  ## Get viewport xscale and yscale
  scale <- vp_scale(hic_plot = hic_plot)

  ## Get viewport name
  currentViewports <- current_viewports()
  vp_name <- paste0("bb_hic", length(grep(pattern = "bb_hic", x = currentViewports)) + 1)

  ## If placing information is provided but plot == TRUE, set up it's own viewport separate from bb_makepage
  ## Not translating into page_coordinates
  if (is.null(hic_plot$x) & is.null(hic_plot$y)){

    vp <- viewport(height = unit(1, "snpc"), width = unit(1, "snpc"),
                   x = unit(0.5, "npc"), y = unit(0.5, "npc"),
                   clip = "on",
                   xscale = scale[[1]], yscale = scale[[2]],
                   just = "center",
                   name = vp_name)

    if (bb_hicInternal$draw == TRUE){

      vp$name <- "bb_hic1"
      grid.newpage()

    }

  } else {

    ## Convert coordinates into same units as page
    page_coords <- convert_page(object = hic_plot)

    ## Make viewport
    vp <- viewport(height = page_coords$height, width = page_coords$width,
                   x = page_coords$x, y = page_coords$y,
                   clip = "on",
                   xscale = scale[[1]], yscale = scale[[2]],
                   just = bb_hicInternal$just,
                   name = vp_name)
  }

  # ======================================================================================================================================================================================
  # INITIALIZE GTREE FOR GROBS
  # ======================================================================================================================================================================================

  assign("hic_grobs", gTree(vp = vp), envir = bbEnv)

  # ======================================================================================================================================================================================
  # MAKE GROBS
  # ======================================================================================================================================================================================

  if (!is.null(hic_plot$chromstart) & !is.null(hic_plot$chromend)){

    if (nrow(hic) > 0){

      ## Determine which grobs will be squares [[1]] and which will be triangles [[2]]
      shapes <- hic_shapes(hic = hic, hic_plot = hic_plot, half = bb_hicInternal$half)

      if (!is.null(shapes[[1]])){

        ## Make square grobs and add to grob gTree
        hic_squares <- rectGrob(x = shapes[[1]]$x,
                                y = shapes[[1]]$y,
                                just = c("left", "bottom"),
                                width = hic_plot$resolution,
                                height = hic_plot$resolution,
                                gp = gpar(col = NA, fill = shapes[[1]]$color),
                                default.units = "native")

        assign("hic_grobs", addGrob(gTree = get("hic_grobs", envir = bbEnv), child = hic_squares), envir = bbEnv)

      }

      ## Make triangle grobs and add to grob gTree
      if (!is.null(shapes[[2]])){

        invisible(apply(shapes[[2]], 1, hic_diagonal, hic_plot = hic_plot, half = bb_hicInternal$half))

      }

    } else {

      warning("Warning: no data found in region.  Suggestions: check chromosome, check region.", call. = FALSE)

    }


  }


  # ======================================================================================================================================================================================
  # IF PLOT == TRUE, DRAW GROBS
  # ======================================================================================================================================================================================

  if (bb_hicInternal$draw == TRUE){

    grid.draw(get("hic_grobs", envir = bbEnv))

  }

  # ======================================================================================================================================================================================
  # ADD GROBS TO OBJECT
  # ======================================================================================================================================================================================

  hic_plot$grobs <- get("hic_grobs", envir = bbEnv)

  # ======================================================================================================================================================================================
  # RETURN OBJECT
  # ======================================================================================================================================================================================
  if (is.null(hic_plot$altchrom)){

    hic_plot$altchrom = hic_plot$chrom
    hic_plot$altchromstart = hic_plot$chromstart
    hic_plot$altchromend = hic_plot$chromend

  }

  return(hic_plot)

  }
