#!groovy

// Important
// Remember to ensure that the Project version information is on top of the pom.xml file because
// the getVersionFromPom will attempt to read the version information that it encounter at the
// first occurance.

node('maven') {

  def mvnCmd = "mvn -s ./openshift-nexus-settings.xml"
  def nexusReleaseURL = "http://nexus3:8081/repository/releases"
  def mavenRepoURL = "http://nexus3:8081/repository/maven-all-public/"
  def projectNamePrefix = ""
  def projectName = "${projectNamePrefix}dm1"
  def wildcardDNS = ".apps.3.1.190.191.nip.io"
  def kieserver_keystore_password="mykeystorepass"
  
  stage('Checkout Source') {
    checkout scm
  }
 
  // In order to access to pom.xml, these variables and method calls must be placed after checkout scm.
  def groupId    = getGroupIdFromPom("pom.xml")
  def artifactId = getArtifactIdFromPom("pom.xml")
  def version    = getVersionFromPom("pom.xml")
  def packageName = getGeneratedPackageName(groupId, artifactId, version)
  
  
  stage('Build jar') {
    sh "${mvnCmd} package -DskipTests=true"
  }

  stage('Publish jar to Nexus') {
    echo "Publish jar file to Nexus..."
    // Remove the ::default from altDeploymentRepository due to the bugs reported at 
    // https://issues.apache.org/jira/browse/MDEPLOY-244?focusedCommentId=16648217&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-16648217
    // https://support.sonatype.com/hc/en-us/articles/360010223594-maven-deploy-plugin-version-3-0-0-M1-deploy-fails-with-401-ReasonPhrase-Unauthorized
    // sh "${mvnCmd} deploy -DskipTests=true -DaltDeploymentRepository=nexus::default::${nexusReleaseURL}"
    sh "${mvnCmd} deploy -DskipTests=true -DaltDeploymentRepository=nexus::${nexusReleaseURL}"
    echo "Generated jar file: ${packageName}"
  }

  stage('Deploy Decision Services') {
    SH_SERVICE = sh (
      script: "oc get svc gobear-travel-insurance-rules-kieserver --no-headers=true --ignore-not-found=true -n ${projectName}",
      returnStdout: true
    ).trim()
    if ("${SH_SERVICE}" == ""){
      SH_SECRET = sh (
        script: "oc get secret kieserver-app-secret --ignore-not-found=true -n ${projectName}",
        returnStdout: true
      ).trim()
      if ("${SH_SECRET}" == ""){
        echo "keystore-app-secret not available. Creating now ..."
        echo "Generating keystore.jks..."
        sh "keytool -genkeypair -alias jboss -keyalg RSA -keystore ./keystore.jks -storepass ${kieserver_keystore_password} --dname 'CN=demo1,OU=Demo,O=ocp.demo.com,L=KL,S=KL,C=MY'"
        echo "Creating kieserver-app-secret..."
        sh "oc create secret generic kieserver-app-secret --from-file=./keystore.jks -n ${projectName}"
      }
      echo "Deploying Decision Server into OCP ..."
      sh "oc new-app -f ./temnplates/rhdm73-kieserver.yaml -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret -p APPLICATION_NAME=gobear-travel-insurance-rules -p KIE_SERVER_HTTPS_PASSWORD=${kieserver_keystore_password} -p KIE_SERVER_CONTAINER_DEPLOYMENT=gobear-rules=com.myspace:gobear:1.0.0 -p KIE_SERVER_MODE=DEVELOPMENT -p KIE_SERVER_MGMT_DISABLED=true -p KIE_SERVER_STARTUP_STRATEGY=LocalContainersStartupStrategy -p MAVEN_REPO_URL=http://nexus3:8081/repository/releases -p MAVEN_REPO_USERNAME=admin -p MAVEN_REPO_PASSWORD=admin123 -n ${projectName}"
    }
    else{
      echo "Rollout POD to have the container to use the lastest build jar from nexus repo..."
      sh "oc rollout latest dc/gobear-travel-insurance-rules-kieserver -n ${projectName}"
    }
  }

}

// Convenience Functions to read variables from the pom.xml
// Do not change anything below this line.
def getVersionFromPom(pom) {
  def matcher = readFile(pom) =~ '<version>(.+)</version>'
  matcher ? matcher[0][1] : null
}
def getGroupIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
  matcher ? matcher[0][1] : null
}
def getArtifactIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
  matcher ? matcher[0][1] : null
}

def getGeneratedPackageName(groupId, artifactId, version){
    String warFileName = "${groupId}.${artifactId}"
    warFileName = warFileName.replace('.', '/')
    "${warFileName}/${version}/${artifactId}-${version}.jar"
}