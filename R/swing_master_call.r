#' Master function for computing Swing statistic
#'
#' @description This is a wrapper function for performing all KinSwingR tasks 
#' simultaneously.
#' @param kinase.table A data.frame of substrate sequences for known kinases. 
#' Format of data must be as follows: Column 1 - kinase or kinase family name 
#' and Column 2 - centered peptide seqeuence.
#' @param input.data A data.frame of phoshopeptide data derived from a 
#' phosphoproteome experiment. Must contain 4 columns and the following format 
#' must be adhered to. Column 1 - Annotation, Column 2 - centered peptide 
#' sequence, Column 3 - Fold Change [-ve to +ve], Column 4 - p-value [0-1]. 
#' This must be the same data.frame used in score.sequences()
#' @param wild.card Letter to describe sequences that are outside of the protein
#'  after centering on the phosphosite (e.g ___MERSTRELCLNF). Default: "_".
#' @param substrate.length Full length of substrate sequence (default is 15). 
#' Will be trimmed automatically or report error if sequences in kinase.table 
#' are not long enough.
#' @param remove.center Remove all peptide seqeuences with the center letter 
#' matching an amino acid (e.g. "y"). Default = FALSE.
#' @param background Presently the only option is to generate a random 
#' background for PWM scoring from the input list. Future versions will enable 
#' the background to be input here as an option. Default: "random"
#' @param n Number of permutations to perform for calculating PWM match scores. 
#' Default: "1000"
#' @param force.trim This function is currently not enabled in the current 
#' version. Future versions will detect if a peptide sequence is of different 
#' length to the PWM models generated by using the option: "TRUE". This will 
#' trim the input the sequences to the same length as the PWM models. Default: 
#' "FALSE"
#' @param pseudo.count Pseudo-count for avoiding log-zero transformations. 
#' Default: "1"
#' @param p.cut.pwm Significance level for determining a significant kinase-
#' substrate enrichment. Default: "0.05"
#' @param p.cut.fc Significance level for determining a significant level of 
#' Fold-change in the phosphoproteomics data. Default: "0.05"
#' @param permutations Number of permutations to perform when calculating swing 
#' p-values. To not perform permutations and only generate the scores, set 
#' permutations=1 or permutations=FALSE. Default: "1000"
#' @param seed This is for reproducible results for permutation testing. To not
#'  use a set seed=NULL. Default: "1234"
#' @param verbose Turn verbosity on/off. To turn on, verbose=TRUE. Options are:
#'  "TRUE, FALSE". Default=FALSE
#' @param threads Number of processing cores to use. Default: "1"
#' @param pseudo Small number to add to values for PWM log transformation to 
#' prevent log transformation of negative numbers. Default = 0.01
#'
#' @examples
#' ## import data
#' data(example_phosphoproteome)
#' data(phosphositeplus_human)
#'
#' ## clean up the annotations
#' ## sample 100 data points for demonstration
#' sample.data <- head(example_phosphoproteome, 100)
#' annotated.data <- clean.annotation(input.data=sample.data)
#'
#' ## sample the kinase-substrate data for demonstration:
#' set.seed(1)
#' sample.pwm <- phosphositeplus_human[sample(nrow(phosphositeplus_human), 
#' 1000),]
#'
#' ## Run Swing analysis:
#' ## For this example, permutations are set to 10 for speed.
#' swing.out <- swing.master(kinase.table = sample.pwm,
#'                           input.data = annotated.data,
#'                           threads = 4,
#'                           permutations = 10)
#'
#' @return data.frame of swing scores and p-values (if network permutation 
#' conducted)
#'
#' @export swing.master

swing.master <- function(input.data = NULL,
                         kinase.table = NULL,
                         wild.card = "_",
                         substrate.length = 15,
                         remove.center = FALSE,
                         background = "random",
                         n = 1000,
                         force.trim = FALSE,
                         seed = 1234,
                         pseudo.count = 1,
                         p.cut.pwm = 0.05,
                         p.cut.fc = 0.05,
                         permutations = 100,
                         verbose = FALSE,
                         threads = 1) {
  if (verbose) {
    cat("[Step1/3] : Building PWMs\n")
  }
  
  #1. build PWMs
  pwm.out <-
    build.pwm(
      kinase.table = kinase.table,
      wild.card = wild.card,
      substrate.length = substrate.length,
      remove.center = remove.center,
      verbose = verbose
    )
  
  if (verbose) {
    cat("[Step2/3] : Scoring PWM matches to peptide sequences\n")
  }
  
  #2. Score PWM matches to peptide sequences
  scores.out <-
    score.sequences(
      input.data,
      background = background,
      pwm.in = pwm.out,
      n = n,
      force.trim = force.trim,
      seed = seed,
      verbose = verbose,
      threads = threads
    )
  
  if (verbose) {
    cat("[Step3/3] : Computing Swing scores\n")
  }
  
  #3. Generate the swing scores:
  swing.out <-
    swing(
      input.data = input.data,
      pwm.in = pwm.out,
      pwm.scores = scores.out,
      pseudo.count = pseudo.count,
      p.cut.pwm = p.cut.pwm,
      p.cut.fc = p.cut.fc,
      permutations = permutations,
      verbose = verbose,
      threads = threads
    )
  
  if (verbose) {
    cat("[COMPLETE]\n")
  }
  
  return(swing.out)
}
