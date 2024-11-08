#
# Start of Settings
#

#
# See the README file for more information
#
##
## NOTE 2023-02 Deucalion - Most of these feed configs are old and were unused for years, verify the url before reinstating each
##

namespace eval ::rss-synd {
	variable rss
	variable default

## 2023-02 Deucalion - This feed causes a connection abort for some reason unknown
#	set rss(theregister) {
#		"url"			"https://www.theregister.com/headlines.atom"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/theregister.db"
#		"trigger"		"!@@feedid@@"
#		"output"                "\[\002TheRegister\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}
##
	set rss(krebs) {
		"url"			"https://krebsonsecurity.com/feed/"
		"channels"		"#rss-bot"
		"database"		"./scripts/rss-feeds/krebs.db"
		"trigger"		"!@@feedid@@"
                "output"                "\[\002Krebs\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
	}

## 2023-02 Deucalion - This feed causes a connection abort for some reason unknown
#	set rss(securityweek) {
#		"url"			"https://www.securityweek.com/feed/"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/securityweek.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002SecurityWeek\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}
##

	set rss(bbc-tech) {
		"url"			"https://feeds.bbci.co.uk/news/technology/rss.xml?edition=int"
		"channels"		"#rss-bot"
		"database"		"./scripts/rss-feeds/bbc-tech.db"
		"trigger"		"!@@feedid@@"
                "output"                "\[\002BBC Tech\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
	}

#	set rss(wired-enterprise) {
#		"url"			"http://feeds.wired.com/wiredenterprise/"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/wired-enterprise.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002Wired\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(wired-science) {
#		"url"			"http://feeds.wired.com/wiredscience"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/wired-science.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002Wired\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-bioscience) {
#		"url"			"http://www.nist.gov/rss/bioscienceandhealth.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/nist-bioscience.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-buildfire) {
#		"url"			"http://www.nist.gov/rss/buildingandfireresearch.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/nist-buildfire.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-chemistry) {
#		"url"			"http://www.nist.gov/rss/chemistry.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/nist-chemistry.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

	set rss(nist-cyber) {
		"url"			"https://www.nist.gov/news-events/cybersecurity/rss.xml"
		"channels"		"#rss-bot"
		"database"              "./scripts/rss-feeds/nist-cyber.db"
		"trigger"               "!@@feedid@@"
		"output"                "\[\002NIST Cyber\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
	}

#	set rss(nist-electronics) {
#		"url"                   "http://www.nist.gov/rss/electronicsandtelecommunications.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-electronics.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-energy) {
#		"url"                   "http://www.nist.gov/rss/energy.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-energy.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-forensics) {
#		"url"                   "http://www.nist.gov/rss/forensics.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-forensics.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-it) {
#		"url"                   "http://www.nist.gov/rss/informationtechnology.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-it.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-manufacturing) {
#		"url"                   "http://www.nist.gov/rss/manufacturing.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-manufacturing.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-math) {
#		"url"                   "http://www.nist.gov/rss/math.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-math.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-nano) {
#		"url"                   "http://www.nist.gov/rss/nanotechnology.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-nano.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-physics) {
#		"url"                   "http://www.nist.gov/rss/physics.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-physics.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(nist-standards) {
#		"url"                   "http://www.nist.gov/rss/standards.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/nist-standards.db"
#		"trigger"               "!@@feedid@@"
#		"output"                "\[\002NIST\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(gibson) {
#		"url"			"http://feeds.feedburner.com/SteveGibsonsBlog"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/gibson.db"
#		"trigger"		"!@@feedid@@"
#               "output"                "\[\002SteveGibson\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

	set rss(nsa) {
		"url"			"https://www.nsa.gov/DesktopModules/ArticleCS/RSS.ashx?ContentType=1&Site=1282&max=20"
		"channels"		"#rss-bot"
		"database"		"./scripts/rss-feeds/nsa.db"
		"trigger"		"!@@feedid@@"
		"output"                "\[\002NSA\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
	}

#	set rss(schneier) {
#		"url"			"http://www.schneier.com/blog/atom.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/schneier.db"
#		"trigger"		"!@@feedid@@"
#		"output"		"\[\002Schneier\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(darpa)	{
#		"url"			"http://www.darpa.mil/Rss.aspx?Colid=24"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/darpa.db"
#		"trigger"		"!@@feedid@@"
#	}

#	set rss(cnet) {
#		"url"			"http://feeds.feedburner.com/cnet/tcoc?format=xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/cnet.db"
#		"trigger"		"!@@feedid@@"
#		"output"                "\[\002CNET\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

## 2023-02 Deucalion - This feed causes a connection abort for some reason unknown
#	set rss(arstechnica) {
#		"url"			"https://feeds.arstechnica.com/arstechnica/index?format=xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/arstechnica.db"
#		"trigger"		"!@@feedid@@"
#		"output"                "\[\002ArsTechnica\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}
##

#	set rss(physorg) {
#		"url"			"https://phys.org/rss-feed/"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/physorg.db"
#		"trigger"		"!@@feedid@@"
#		"output"                "\[\002PhysOrg\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#       set rss(sciencedaily_all) {
#		"url"			"http://feeds.sciencedaily.com/sciencedaily?format=xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/sciencedaily_all.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"                "\[\002ScienceDaily\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#        }

#	set rss(nature) {
#		"url"			"http://feeds.nature.com/news/rss/news"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/nature.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"                "\[\002Nature\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(sciencemag) {
#		"url"			"http://news.sciencemag.org/rss/current.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/sciencemag.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"                "\[\002ScienceMag\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(singularityhub) {
#		"url"			"http://singularityhub.com/feed/"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/singularityhub.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"		"\[\002SingularityHub\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(thescientist) {
#		"url"			"http://www.the-scientist.com/?rss.feed/categoryNo/2901/News---Opinion/"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/thescientist.db"
#		"trigger"		"!@@feedid@@"
#		"output"		"\[\002TheScientist\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

	set rss(mittech) {
		"url"			"https://www.technologyreview.com/feed/"
		"channels"		"#rss-bot"
		"database"		"./scripts/rss-feeds/mittech.db"
		"trigger"		"!@@feedid@@"
		"charset"		"utf-8"
		"output"		"\[\002MIT Tech Review\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
	}

#	set rss(berkeleyit) {
#		"url"			"http://research-it.berkeley.edu/news/rss.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/berkeleyit.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"		"\[\002BerkeleyIT\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(uclascitech) {
#		"url"			"http://newsroom.ucla.edu/cats/science_+_technology.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/uclascitech.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#		"output"		"\[\002UCLASciTech\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(uclahealth) {
#		"url"			"http://newsroom.ucla.edu/cats/health_+_behavior.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/uclahealth.db"
#		"trigger"               "!@@feedid@@"
#		"charset"               "utf-8"
#		"output"                "\[\002UCLAHealth\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#        set rss(uclaenvironment) {
#		"url"                   "http://newsroom.ucla.edu/cats/environment_+_climate.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/uclaenvironment.db"
#		 "trigger"               "!@@feedid@@"
#		"charset"               "utf-8"
#		"output"                "\[\002UCLAEnvironment\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(innovationsreport) {
#		"url"                   "http://www.innovations-report.com/rss.xml"
#		"channels"              "#rss-bot"
#		"database"              "./scripts/rss-feeds/innovationsreport.db"
#		"trigger"               "!@@feedid@@"
#		"charset"               "utf-8"
#		"output"                "\[\002InnovationsReport\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
#	}

#	set rss(SoylentNews) {
#		"url"			"http://soylentnews.org/index.rss"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/SoylentNews.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#	}

#	set rss(mosaicscience) {
#		"url"			"http://mosaicscience.com/feed/rss.xml"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/mosaicscience.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#	}

#	set rss(pipedot) {
#		"url"			"http://pipedot.org/atom"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/pipedot.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#	}

#	set rss(hn) {
#		"url"			"https://news.ycombinator.com/rss"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/HN.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#	}

#	set rss(threat) {
#		"url"			"http://threatpost.com/feed"
#		"channels"		"#rss-bot"
#		"database"		"./scripts/rss-feeds/threatpost.db"
#		"trigger"		"!@@feedid@@"
#		"charset"		"utf-8"
#	}

	# The default settings, If any setting isn't set for an individual feed
	#   it'll use the defaults listed here.
	#
	# WARNING: You can change the options here, but DO NOT REMOVE THEM, doing
	#   so will create errors.
	set default {
		"announce-output"	10
		"trigger-output"	99
		"remove-empty"		1
		"trigger-type"		3:2
		"announce-type"		0
		"max-depth"		5
		"evaluate-tcl"		0
		"update-interval"	30
		"output-order"		1
		"timeout"		60000
		"channels"		"#rss-bot"
		"trigger"		"!rss @@feedid@@"
		"output"		"\[\002@@channel!title@@@@title@@\002\] @@item!title@@@@entry!title@@ - @@item!link@@@@entry!link!=href@@"
		"user-agent"		"Mozilla/5.0 (Windows; U; Windows NT 6.1; en-GB; rv:1.9.2.2) Gecko/20100316 Firefox/3.6.2"
	}
}

#
# End of Settings
#
################################################################################
