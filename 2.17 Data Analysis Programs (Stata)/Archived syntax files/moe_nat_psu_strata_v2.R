moe=function(prob,rs,wt,sd=NULL,psu=NULL,strata=NULL,conf.level=0.95){
  # Computes margins of error around the estimated prevalence, as the result of the
  # combination of sampling error and measurement error
  # prob = probability of being beyond the threshold for each case
  # rs = raw score for each case
  # wt = weight to be assigned to each case
  # psu = "cluster" variable (primary sampling unit)
  # strata (as there are strata with singleton PSU,need to use "survey.lonely.psu" options)
  # Compute the average probability for each rs
  n = length(prob)
  if (is.null(wt)) {wt = rep(1,n)}
  if (is.null(sd)) {sd = 1}
  if(is.null(strata) | sum(is.na(strata))==length(strata)) strata=rep(1,n)
  if(is.null(psu) | sum(is.na(psu))==length(psu)) psu=rep(1,n)
  options(survey.lonely.psu = "adjust")
  # Impute all missing in psu and strata
  if(sum(is.na((psu)))==length(psu)) psu=rep(1, length(prob))
  if(sum(is.na((strata)))==length(strata)) strata=rep(1, length(prob))
  svydesign=svydesign(id=psu,weights = ~ wt,strata=strata,nest=T,lonely.psu=getOption("survey.lonely.psu"="adjust"),
                      data=data.frame(prob))
  se_s = SE(svymean(~prob, svydesign,  deff = T,na.rm=T))*sd
  deff_s = deff(svymean(~prob, svydesign,  deff = "replace",na.rm=T))*sd
  p = sort(unique(prob))%*%table(prob,rs)/colSums(table(prob,rs))
  wrs = NULL
  for (i in sort(unique(rs))){
    wrs[i+1] = sum(wt[which(rs==i)])/sum(wt)*length(wt)
  }
  wrs=wrs[!is.na(wrs)]
  var_m = (p*(1-p)/n)%*%(wrs/sum(wrs))^2
  se_m = sqrt(var_m)
  se = sqrt(se_s^2+se_m^2)
  moe = se*(-qnorm((1-conf.level)/2))
  return(list(moe=moe, se_m=se_m,se_s=se_s,deff_s=deff_s))
}
