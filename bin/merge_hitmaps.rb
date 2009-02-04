#!/usr/bin/env ruby

# This script checks the pathway coverage of structures

require File.join(File.dirname(__FILE__), 'script_common')

require 'optparse'

glycomedb_results = <<__GLYCOME_RESULTS__
hsa00512 {1}NeuAc(a2-u)[{2}NeuAc(a2-8){0}NeuAc(a2-6)][{2}Gal(b1-u){2}GlcNAc(u1-u)[{1}Gal(b1-u){1}GlcNAc(b1-u)[{1}Fuc(a1-2)]{6}Gal(b1-u)[{4}Fuc(a1-u)]{6}GlcNAc(b1-u)[{1}NeuAc(a2-6)][{1}Gal(b1-u)[{2}Gal(b1-u)[{2}Gal(b1-u)[{1}Gal(b1-u){1}GlcNAc(b1-6){1}Gal(b1-4)]{3}GlcNAc(b1-6){3}Gal(b1-4)]{5}GlcNAc(b1-6){11}Gal(b1-4)][{2}Fuc(a1-3)]{12}GlcNAc(b1-6)][{5}GlcNAc(a1-4)][{5}Gal(a1-3)][{54}NeuAc(a2-3)][{3}Gal(b1-u)[{14}Fuc(a1-4)][{5}Fuc(a1-2)[{3}NeuAc(a2-3)][{3}Fuc(a1-3)[{1}NeuAc(a2-2)[{2}NeuAc(a2-3)][{1}Gal(b1-4){1}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3)]{9}Gal(b1-4)][{4}Fuc(a1-4)][{2}Fuc(a1-2){4}Gal(b1-3)]{13}GlcNAc(b1-3)]{42}Gal(b1-4)][{11}Fuc(a1-3)][{15}Fuc(a1-2)[{4}NeuAc(a2-3)]{34}Gal(b1-3)]{79}GlcNAc(b1-3)][{7}GalNAc(a1-3)][{67}Fuc(a1-2)]{0}Gal(b1-4)][{12}Fuc(a1-4)][{1}Fuc(a1-2)[{2}NeuAc(a2-3)]{13}Gal(b1-3)][{73}Fuc(a1-3)][{2}Fuc(a1-2)[{4}NeuAc(a2-3)]{13}Gal(b1-u)][{5}Fuc(a1-u)][{1}NeuAc(a2-u)][{1}Fuc(a1-u)[{1}GlcNAc(u1-u)]{4}Gal(u1-u)]{0}GlcNAc(b1-6)][{1}Gal(b1-4){1}GlcNAc(b1-3){8}Gal(b1-6)][{1}GalNAc(b1-6)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl|9acetyl(a2-6)][{2}NeuGc(a2-6)][{2}GalNAc(a1-3)][{1}Gal(a1-3)][{2}NeuAc(a2-3){4}GalNAc(b1-3)][{6}Fuc(a1-u)[{4}NeuAc(a2-6)][{5}Fuc(a1-2)[{1}NeuAc(a2-6)][{1}NeuAc(a2-3)]{19}Gal(b1-4)[{4}Fuc(a1-4)]{30}GlcNAc(b1-6)][{3}GlcNAc(a1-4)][{1}GalNAc(a1-4)][{1}Fuc(a1-2){1}Gal(b1-3){2}GlcNAc(b1-4)][{5}GalNAc(b1-4)][{4}Gal(a1-3)][{11}GalNAc(a1-3)][{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u){1}GlcNAc(b1-3)[{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u){1}GlcNAc(b1-6)]{1}Gal(b1-4){1}GlcNAc(b1-3)[{1}NeuAc(a2-3)]{2}Gal(b1-3)][{4}Fuc(a1-u)[{8}Fuc(a1-2)[{4}GalNAc(a1-3)]{8}Gal(b1-u)]{8}GlcNAc(b1-u)[{2}Fuc(a1-2){2}Gal(b1-4){2}GlcNAc(b1-6)][{1}Fuc(a1-2){1}Gal(b1-u){1}GlcNAc(b1-3)[{1}Fuc(a1-2){1}Gal(b1-4){1}GlcNAc(b1-6)]{1}Gal(b1-u){1}GlcNAc(b1-3){1}Gal(b1-3)][{1}NeuAc(a2-3)][{2}GalNAc(a1-3)][{1}Gal(a1-3)][{1}Fuc(a1-2){2}Gal(b1-u){2}GlcNAc(b1-3)][{11}Fuc(a1-2)]{25}Gal(b1-u)[{13}Fuc(a1-4)][{7}Fuc(a1-2)[{2}NeuAc(a2-6)][{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u)[{3}Fuc(a1-2)[{1}Gal(a1-3)]{7}Gal(b1-4)][{1}Fuc(a1-3)][{1}Fuc(a1-2){2}Gal(b1-3)]{12}GlcNAc(b1-6)][{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u)[{1}Gal(b1-4){1}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3){10}Gal(b1-4)][{1}GlcNAc(b1-4)][{1}Fuc(a1-4)][{1}NeuAc(a2-3){1}Gal(b1-3)][{1}Fuc(a1-3)]{13}GlcNAc(b1-3)][{12}NeuAc(a2-3)]{66}Gal(b1-4)][{17}Fuc(a1-3)][{13}Fuc(a1-2)[{2}GalNAc(a1-3)][{1}Fuc(a1-2)[{1}NeuAc(a2-3)]{4}Gal(b1-3)[{3}Fuc(a1-4)]{4}GlcNAc(b1-3)][{6}NeuAc(a2-3)][{1}Gal(a1-3)]{36}Gal(b1-3)][{2}Fuc(a1-u)]{143}GlcNAc(b1-3)][{1}GlcNAc(a1-3)][{2}NeuAc(a2-8){0}NeuAc(a2-3)][{51}Fuc(a1-2)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5amino(a2-u)][{2}NeuAc(a2-u)[{1}Gal(a1-3)][{2}GalNAc(a1-3)][{22}Fuc(a1-2)]{24}Gal(b1-u)[{2}Gal(b1-3)[{2}Gal(b1-4)]{4}GlcNAc(b1-u)[{4}Fuc(a1-2)]{10}Gal(b1-4)][{4}Fuc(a1-3)][{2}Fuc(a1-2){5}Gal(b1-3)][{2}Fuc(a1-u)]{39}GlcNAc(b1-u)][{1}NeuAc(a2-u){1}NeuAc(a2-u){6}NeuAc(a2-u)]{0}Gal(b1-3)][{1}Fuc(a1-2)[{1}GlcNAc(b1-3){1}Gal(b1-u){2}GlcNAc(b1-3)][{1}GlcNAc(a1-3)]{7}Gal(b1-u)[{1}NeuAc(a2-6)][{1}Fuc(a1-4)][{18}Fuc(a1-2)[{2}GalNAc(a1-3)[{4}NeuAc(a2-6)]{5}Gal(b1-3)[{5}GalNAc(a1-3)[{2}NeuAc(a2-6)]{14}Gal(b1-4)]{25}GlcNAc(b1-6)][{11}NeuAc(a2-6)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4){1}GlcNAc(a1-3)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-u)[{7}Fuc(a1-2)[{1}Fuc(a1-6)][{1}GalNAc(b1-3)][{2}Fuc(a1-2)[{2}GalNAc(a1-3)]{2}Gal(b1-4){2}GlcNAc(b1-3)][{11}GalNAc(a1-3)]{26}Gal(b1-4)][{3}Fuc(a1-2)[{2}GalNAc(a1-6)][{4}NeuAc(a2-6)][{6}GalNAc(a1-3)]{16}Gal(b1-3)]{47}GlcNAc(b1-3)][{15}NeuAc(a2-3)]{118}Gal(b1-4)][{17}Fuc(a1-2)[{1}Gal(b1-3){1}GlcNAc(b1-6)][{2}NeuAc(a2-3)][{1}GalNAc(a1-3)][{2}Gal(b1-u)[{1}Gal(b1-3)]{3}GlcNAc(b1-3)]{40}Gal(b1-3)][{20}Fuc(a1-3)]{0}GlcNAc(b1-3)][{2}Gal(b1-4){2}GlcNAc(b1-u)]{0}GalNAc
hsa00601 {1}Fuc(a1-2)[{1}Fuc(a1-3)[{2}Gal(b1-4)]{2}GlcNAc(a1-6)][{21}Fuc(a1-3)[{2}Fuc(a1-3)[{1}Gal(b1-4){1}GlcNAc(b1-6)][{8}NeuAc(a2-6)][{1}Gal(b1-u)[{6}Gal(b1-4)][{3}Fuc(a1-4)][{4}Fuc(a1-2){9}Gal(b1-3)][{3}Fuc(a1-3)]{16}GlcNAc(b1-3)]{43}Gal(b1-4)]{43}GlcNAc(b1-6)][{1}Gal(b1-3){2}GalNAc(b1-4)][{3}Gal(b1-u)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-3){1}Gal(b1-6)][{2}NeuGc(a2-6)][{1}NeuAc(u2-6)][{1}NeuAc(a2-8){19}NeuAc(a2-6)][{1}Gal(a1-4)][{1}DFuc(a1-4)][{1}NeuAc(a2-3)][{1}DFuc(a1-2)[{1}NeuAc(a2-6)][{1}Fuc(a1-3)[{1}Gal(b1-4)]{1}GlcNAc(b1-6)][{3}GalNAc(b1-4)][{3}NeuGc(a2-3)][{1}GalNAc(a1-3)][{3}Fuc(a1-3)[{3}Fuc(a1-2){5}Gal(b1-4)][{3}Fuc(a1-4)][{1}Fuc(a1-2)[{1}NeuAc(a2-3)]{7}Gal(b1-3)]{12}GlcNAc(b1-3)][{2}NeuAc(a2-8){0}NeuAc(a2-3)][{1}NeuAc(u2-3)]{0}Gal(b1-3)][{1}NeuAc(a2-u)]{0}GlcNAc(b1-3)]{0}Gal(b1-4){0}Glc
hsa00602 {1}Fuc(a1-2)[{1}DFuc(a1-3)[{1}NeuAc(a2-u)[{2}NeuAc(a2-6)][{4}Gal(b1-3)[{2}Fuc(a1-4)]{4}GlcNAc(b1-3)][{1}Fuc(a1-2)]{17}Gal(b1-4)][{8}Fuc(a1-3)]{17}GlcNAc(b1-6)][{15}Fuc(a1-3)[{1}NeuAc(a2-8){2}NeuAc(a2-u)[{1}Fuc(a1-2){1}Gal(b1-4){1}GalNAc(a1-6)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4){1}GalNAc(b1-6)][{2}Fuc(a1-2)[{1}NeuAc(a2-6)][{3}Gal(a1-3)][{1}NeuAc(a2-3)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4){1}GlcNAc(b1-3){5}GalNAc(a1-3)]{0}Gal(b1-4){0}GlcNAc(b1-6)][{9}NeuAc(a2-6)][{1}GalNAc(b1-4)][{1}Gal(a1-4)][{1}NeuAc(a2-3){2}Gal(b1-3)[{1}Fuc(a1-2){1}Gal(b1-4)]{0}GalNAc(a1-3)][{1}Gal(b1-3)][{1}Gal(b1-3)[{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4)][{1}Fuc(a1-4)]{2}GlcNAc(a1-3)][{1}Gal(a1-3)][{2}GlcA(b1-3)][{1}NeuAc(a2-3)[{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4)]{3}GalNAc(b1-3)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl|9acetyl(a2-8)[{1}NeuGc(a2-8)]{0}NeuAc(a2-3)][{2}Fuc(a1-2)[{1}NeuAc(a2-3)]{13}Gal(b1-3)[{1}NeuAc(a2-u)[{2}Fuc(a1-2)[{1}Gal(a1-3)]{4}Gal(b1-4){4}GlcNAc(b1-6)][{3}NeuAc(a2-6)][{1}Gal(a1-4)][{1}NeuAc(a2-8)[{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl|9acetyl(a2-8)]{0}NeuAc(a2-3)][{1}GalNAc(a1-3)][{3}Gal(a1-3)][{1}Fuc(a1-2){1}Gal(b1-3)[{1}Fuc(a1-4)][{9}Fuc(a1-2)[{1}NeuAc(a2-6)][{5}NeuAc(a2-3)][{2}Fuc(a1-3)[{1}Fuc(a1-2)[{1}Gal(a1-3)][{3}NeuAc(a2-3)]{5}Gal(b1-4)]{5}GlcNAc(b1-3)][{1}Gal(a1-3)][{5}GalNAc(a1-3)]{0}Gal(b1-4)]{0}GlcNAc(b1-3)][{2}GlcA(b1-3)][{1}NeuGc(a2-3)]{0}Gal(b1-4)][{9}Fuc(a1-4)][{4}Fuc(a1-3)][{1}GalNAc(a1-3)]{0}GlcNAc(b1-3)][{1}NeuGc(a2-3)][{1}DFuc(a1-2)][{7}Fuc(a1-3)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-3)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-6)][{1}NeuAc(a2-3)]{1}Gal(b1-4){1}GlcNAc(b1-u)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-6)][{1}NeuAc(a2-3)[{1}NeuAc(a2-3){1}Gal(b1-4)]{2}GlcNAc(b1-3)][{7}Gal(a1-3)][{3}NeuAc(a2-3)][{9}Fuc(a1-2)]{16}Gal(b1-4)]{16}GlcNAc(b1-u)]{0}Gal(b1-4)]{0}GlcNAc(b1-3)]{0}Gal(b1-4){0}Glc
hsa00603 {1}GlcNAc(b1-3)[{1}GalNAc(b1-4)][{1}Fuc(a1-u)[{1}NeuAc(a2-6)][{2}GalNAc(a1-3)[{2}NeuAc(a2-6)]{0}Gal(b1-3)][{1}Gal(a1-3)][{1}GalNAc(b1-3)][{1}NeuAc(a2-3)]{0}GalNAc(b1-3)]{0}Gal(a1-4){0}Gal(b1-4){0}Glc
hsa00604 {1}NeuAc(a2-8){1}NeuAc(a2-2)[{1}Gal(b1-3){1}GalNAc(a1-4)][{5}Fuc(a1-2)[{4}GalNAc(b1-4)][{1}NeuGc(a2-3)][{1}Gal(b1-4){1}Fuc(a1-3){1}GlcNAc(b1-3)]{0}Gal(b1-3)[{1}NeuAc(a2-2){1}Gal(b1-4){1}GlcNAc(b1-3){1}Gal(b1-4)][{1}NeuAc(a2-3)]{0}GalNAc(b1-4)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5amino|9acetyl(a2-8)[{2}NeuAc(a2-8){0}NeuAc(a2-8)][{1}NeuGc(a2-8)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl|9acetyl(a2-8)]{0}NeuAc(a2-3)][{4}NeuGc(a2-3)]{0}Gal(b1-4){0}Glc
hsa00532 {1}NeuAc(a2-u)[{1}NeuAc(a2-6)][{1}NeuAc(a2-3)][{1}GalNAc(a1-4)[{3}Thr(a1-3){0}GalNAc(b1-4)]{0}GlcA(b1-3){0}Gal(b1-3)]{0}Gal(b1-4){0}Xyl
hsa00510 {2}NeuAc(a2-3){4}Gal(b1-4){4}GlcNAc(b1-2){4}Man(a1-u)[{1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-6)][{1}GlcNAc(b1-4){2}GlcNAc(b1-4){3}GlcNAc(b1-4){3}GlcNAc(b1-4)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-u)[{1}NeuAc(a2-3)]{3}Gal(b1-4)][{1}Man(a1-2){1}Man(a1-2){1}Man(a1-u)[{1}Man(a1-2){1}Man(a1-2)]{1}Man(a1-u)[{1}NeuAc(a2-u){4}Gal(b1-4){4}GlcNAc(b1-2)[{1}Man(a1-2){1}Man(a1-6)][{1}Man(a1-2){1}Man(a1-2){1}Man(a1-3)]{5}Man(a1-6)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(b1-6)][{1}Man(a1-2){1}Man(a1-2)[{1}NeuAc(a2-u){3}Gal(b1-4){5}GlcNAc(b1-4)][{1}NeuAc(a2-u){4}Gal(b1-4){4}GlcNAc(b1-2)]{7}Man(a1-3)]{8}Man(a1-4)][{8}Gal(b1-4){8}GlcNAc(b1-2)[{8}Gal(b1-4){8}GlcNAc(b1-4)]{8}Man(a1-3)[{4}Gal(b1-4){4}GlcNAc(b1-2){8}Man(a1-6)]{8}Man(u1-4)][{2}NeuAc(a2-u){2}Gal(b1-4){2}GlcNAc(b1-u)[{2}NeuAc(a2-u){13}Gal(b1-4){13}GlcNAc(b1-6)][{4}Fuc(a1-3)[{6}NeuAc(a2-u)[{1}NeuAc(a2-6)]{26}Gal(b1-4)]{26}GlcNAc(b1-4)][{17}Fuc(a1-3)[{19}NeuAc(a2-u)[{12}NeuAc(a2-6)][{1}GalNAc(a1-3)][{3}Fuc(a1-3)[{4}NeuAc(a2-6){10}Gal(b1-4)]{10}GlcNAc(b1-3)][{4}NeuAc(a2-3)][{1}Fuc(a1-2)]{116}Gal(b1-4)]{121}GlcNAc(b1-2)][{2}Man(a1-u)]{133}Man(a1-u)[{1}NeuAc(a2-u)[{1}NeuAc(a2-4)]{2}Gal(u1-4){2}GlcNAc(u1-2){2}Man(u1-6)][{2}GalNAc(b1-4){2}GlcNAc(b1-2){2}Glc(a1-6)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(b1-6)][{2}Gal(b1-4){2}GlcNAc(b1-6)][{1}NeuAc(a2-u){1}Gal(b1-u){1}GlcNAc(u1-u)[{2}Glc(a1-4){2}GalNAc(b1-6)][{6}Man(a1-2){14}Man(a1-6)][{13}Fuc(a1-3)[{2}NeuAc(a2-6){24}GalNAc(b1-4)][{12}NeuAc(a2-u)[{47}NeuAc(a2-6)][{2}Gal(b1-4){2}GlcNAc(b1-4)][{4}GalNAc(b1-4)][{84}NeuAc(a2-3)][{4}Fuc(a1-3)[{6}Fuc(a1-3)[{4}NeuAc(a2-3){6}Gal(b1-4)]{6}GlcNAc(b1-3)[{1}NeuAc(a2-3)]{18}Gal(b1-4)]{18}GlcNAc(b1-3)][{4}Gal(a1-3)][{2}Fuc(a1-2)]{286}Gal(b1-4)][{2}Gal(b1-4){2}GlcNAc(b1-3){4}Gal(b1-3)]{0}GlcNAc(b1-6)][{1}NeuGc(a2-u)[{44}NeuAc(a2-6)][{50}NeuAc(a2-3)][{4}NeuAc(a2-u)]{115}Gal(b1-4){117}GlcNAc(b1-4)][{1}Fuc(a1-3)][{8}Man(a1-2)[{2}Man(a1-6)]{0}Man(a1-3)][{2}Gal(b1-4){2}GlcNAc(b1-3)][{4}NeuAc(a2-3){6}Gal(b1-4){6}GlcNAc(a1-2)][{96}Fuc(a1-3)[{1}NeuAc(a2-6)][{2}NeuAc(a2-3){2}Gal(b1-4){2}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-6)][{4}Glc(b1-4)][{1}Fuc(a1-2){1}Gal(b1-3)[{5}NeuAc(a2-6)][{1}NeuAc(a2-3)]{59}GalNAc(b1-4)][{2}NeuGc(a2-u)[{1}NeuAc(a2-6){1}Gal(b1-4){1}GlcNAc(b1-u){0}NeuAc(a2-6)][{6}Fuc(a1-6)][{2}Gal(b1-4){2}GlcNAc(b1-4)][{4}GalNAc(b1-4)][{2}GalNAc(a1-3)][{11}Gal(a1-3)][{2}Fuc(a1-3)][{2}Gal(b1-3)][{228}NeuAc(a2-3)][{14}Fuc(a1-3)[{1}Fuc(a1-2)[{2}NeuAc(a2-6)][{2}Gal(b1-4){2}GlcNAc(b1-3){8}Gal(b1-4){8}GlcNAc(b1-3)][{5}NeuAc(a2-3)]{45}Gal(b1-4)]{45}GlcNAc(b1-3)][{1}NeuGc(a2-3)][{23}Fuc(a1-2)][{27}NeuAc(a2-u)]{0}Gal(b1-4)]{0}GlcNAc(b1-2)][{8}Fuc(a1-3)[{1}NeuAc(a2-u)[{1}NeuAc(a2-6)][{1}Gal(b1-4){1}GlcNAc(b1-3)][{1}NeuAc(a2-3)]{17}Gal(b1-4)]{18}GlcNAc(b1-u)][{7}Man(a1-u)]{0}Man(a1-6)][{1}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-3)[{1}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-6)][{2}NeuAc(a2-3){2}Gal(b1-4)]{94}GlcNAc(b1-4)][{2}GlcNAc(b1-2){2}Glc(a1-3)][{1}NeuAc(a2-u)[{1}NeuAc(a2-4)]{2}Gal(u1-4){2}GlcNAc(u1-2){2}Man(u1-3)][{1}NeuAc(a2-u){1}Gal(b1-u){1}GlcNAc(u1-u)[{46}NeuAc(a2-3)[{47}NeuAc(a2-6)]{109}Gal(b1-4){111}GlcNAc(b1-6)][{4}Gal(b1-3)[{1}NeuAc(a2-6){1}GalNAc(b1-4)][{1}NeuGc(a2-u)[{55}NeuAc(a2-6)][{2}Fuc(a1-3)[{2}Gal(b1-4)]{2}GlcNAc(b1-6)][{1}NeuAc(a2-4)][{2}Fuc(a1-3)[{2}Gal(b1-4)]{2}GlcNAc(b1-4)][{10}GalNAc(b1-4)][{6}Gal(a1-3)][{8}Fuc(a1-3)[{6}Fuc(a1-3)[{6}Gal(b1-4)]{6}GlcNAc(b1-3){8}Gal(b1-4)]{8}GlcNAc(b1-3)][{99}NeuAc(a2-3)][{4}Fuc(a1-2)][{15}NeuAc(a2-u)]{367}Gal(b1-4)][{57}Fuc(a1-3)]{0}GlcNAc(b1-4)][{2}Fuc(a1-3)[{2}NeuAc(a2-3){2}Gal(b1-4)]{2}Glc(b1-4)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-3)][{2}NeuAc(a2-6){2}Gal(b1-4){2}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3)[{1}NeuAc(a2-6)]{3}Gal(b1-4){3}GlcNAc(b1-3)][{1}Fuc(a1-3)][{6}NeuAc(a2-3){16}Gal(b1-4){16}GlcNAc(a1-2)][{1}Glc(a1-2){1}Glc(a1-3){7}Glc(a1-3){0}Man(a1-2){0}Man(a1-2)][{4}Fuc(a1-u)[{1}NeuAc(a2-6)][{1}dgal-hex-1:5|2n-acetyl|usulfate(b1-4)][{18}NeuAc(a2-6){139}GalNAc(b1-4)][{2}NeuAc(a2-u){8}Glc(b1-4)][{2}NeuGc(a2-u)[{1}NeuAc(a2-6){1}Gal(b1-4){1}GlcNAc(b1-u){0}NeuAc(a2-6)][{2}GalNAc(b1-4)][{209}NeuAc(a2-3)][{2}Fuc(a1-3)[{4}NeuAc(a2-6){4}Gal(b1-4){4}GlcNAc(b1-3)[{4}NeuAc(a2-6)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5amino(a2-6)][{1}Neu(a2-6)]{23}Gal(b1-4)]{23}GlcNAc(b1-3)][{7}Gal(a1-3)][{12}GalNAc(a1-3)][{44}Fuc(a1-2)][{29}NeuAc(a2-u)]{0}Gal(b1-4)][{1}NeuAc(a2-6){1}Gal(b1-3)][{58}Fuc(a1-3)][{2}Fuc(a1-2)[{2}GalNAc(a1-3)]{4}Gal(b1-u)]{0}GlcNAc(b1-2)][{8}Fuc(a1-3)[{3}NeuAc(a2-u)[{1}NeuAc(a2-6)][{1}NeuAc(a2-3)]{18}Gal(b1-4)]{21}GlcNAc(b1-u)]{0}Man(a1-3)][{6}Gal(b1-4){6}GlcNAc(b1-2)[{2}Fuc(a1-3)[{2}Gal(b1-4)]{2}GlcNAc(b1-4)][{4}Fuc(a1-3)[{4}Gal(b1-4)]{4}GlcNAc(b1-3)]{6}Man(b1-3)][{1}Xyl(b1-2)][{1}GlcNAc(b1-2)]{0}Man(b1-4)][{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-3)][{1}Fuc(a1-3)]{0}GlcNAc(b1-4){0}GlcNAc
__GLYCOME_RESULTS__

glycosuite_results = <<__GLYCOSUITE_RESULTS__
hsa00512 {6}Fuc(a1-2)[{2}GalNAc(a1-3)]{6}Gal(b1-u)[{1}Fuc(a1-u)]{6}GlcNAc(b1-u)[{3}Fuc(a1-2){3}Gal(b1-u)[{2}Fuc(a1-4)][{7}Fuc(a1-2)[{1}NeuAc(a2-3)][{1}GalNAc(a1-3)]{15}Gal(b1-4)]{23}GlcNAc(b1-6)][{2}NeuAc(a2-6)][{1}NeuAc(u2-6)][{5}HSO3(u1-6)][{1}HSO3(u1-4)][{1}GlcNAc(a1-4)][{2}GalNAc(b1-4)][{5}GalNAc(a1-3)][{2}Fuc(a1-2)[{2}Gal(a1-3)]{2}Gal(b1-u){2}GlcNAc(b1-3)[{2}Fuc(a1-2)[{2}Gal(a1-3)]{2}Gal(b1-u){2}GlcNAc(b1-6)]{2}Gal(b1-4){2}GlcNAc(b1-3){2}Gal(b1-3)][{2}NeuAc(u2-3)][{4}Fuc(a1-2)[{2}GalNAc(a1-3)]{4}Gal(b1-u)[{3}Fuc(a1-u)]{4}GlcNAc(b1-u)[{1}Fuc(a1-2){1}Gal(b1-u)[{8}Fuc(a1-2)[{5}GalNAc(a1-3)]{8}Gal(b1-4)]{9}GlcNAc(b1-6)][{5}Fuc(a1-2)[{4}Fuc(a1-2)[{1}GalNAc(a1-3)]{4}Gal(b1-4){4}GlcNAc(b1-6)][{1}GalNAc(a1-3)][{3}Fuc(a1-2)[{1}GalNAc(a1-3)]{3}Gal(b1-u){4}GlcNAc(b1-3)]{9}Gal(b1-u)[{1}Gal(b1-4)][{1}Gal(b1-3)]{11}GlcNAc(b1-3)][{5}GalNAc(a1-3)][{1}Gal(a1-3)][{16}Fuc(a1-2)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-u){1}GlcNAc(a1-u)]{32}Gal(b1-u)[{2}HSO3(u1-6)][{7}Fuc(a1-4)][{1}Fuc(a1-2){1}Gal(b1-u){1}GlcNAc(b1-u)[{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u){1}GlcNAc(b1-6)][{3}HSO3(u1-6)][{3}NeuAc(a2-6)][{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-u)[{1}Gal(b1-4)][{1}Fuc(a1-3)]{2}GlcNAc(b1-3)][{7}NeuAc(a2-3)][{5}Fuc(a1-2)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-u){1}GlcNAc(a1-u)]{27}Gal(b1-4)][{13}Fuc(a1-2)[{1}Fuc(a1-3)[{1}Gal(b1-4)]{1}GlcNAc(b1-6)][{1}Gal(a1-3)][{2}Gal(b1-3)[{1}Fuc(a1-4)]{2}GlcNAc(b1-3)][{2}NeuAc(a2-3)][{2}GalNAc(a1-3)]{26}Gal(b1-3)][{10}Fuc(a1-3)][{2}Fuc(a1-u)]{93}GlcNAc(b1-3)][{1}HSO3(u1-3)][{3}Gal(a1-3)][{1}NeuAc(a2-8){0}NeuAc(a2-3)][{27}Fuc(a1-2)][{3}NeuAc(u2-u)][{1}Fuc(a1-u)][{3}NeuAc(a2-u)]{0}Gal(b1-3)[{1}NeuAc(a2-8){0}NeuAc(a2-6)][{2}NeuAc(u2-u){2}Gal(u1-u)[{14}HSO3(u1-6)][{1}NeuAc(a2-u)[{1}Fuc(a1-3)[{4}Gal(b1-4)]{4}GlcNAc(b1-6)][{3}HSO3(u1-6)][{1}NeuAc(a2-6)][{2}GlcNAc(a1-4)][{4}Gal(a1-3)][{14}GalNAc(a1-3)][{7}HSO3(u1-3)][{32}NeuAc(a2-3)][{9}Fuc(a1-2)[{1}HSO3(u1-3)]{18}Gal(b1-3)[{9}Fuc(a1-4)][{2}Fuc(a1-2)[{1}NeuAc(a2-6)][{2}NeuAc(a2-3)][{1}Fuc(a1-2){2}Gal(b1-3)[{1}Gal(b1-4){1}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3)[{2}NeuAc(a2-3)]{8}Gal(b1-4)][{2}Fuc(a1-4)][{2}Fuc(a1-3)]{10}GlcNAc(b1-3)]{22}Gal(b1-4)][{8}Fuc(a1-3)]{42}GlcNAc(b1-3)][{50}Fuc(a1-2)][{2}Gal(b1-u)[{2}Fuc(a1-3)[{1}NeuAc(a2-6){3}Gal(b1-4)]{3}GlcNAc(b1-u)[{2}NeuAc(a2-6)]{8}Gal(b1-4)][{3}Fuc(a1-3)][{1}Fuc(a1-u)]{10}GlcNAc(b1-u)][{1}Fuc(a1-u)]{0}Gal(b1-4)][{7}Fuc(a1-4)][{39}Fuc(a1-3)][{1}Fuc(a1-2){3}Gal(b1-3)][{3}Fuc(a1-u)][{1}Gal(b1-u){1}GlcNAc(u1-u)[{3}NeuAc(a2-3)][{1}GlcNAc(u1-3)][{2}Fuc(a1-2)]{11}Gal(b1-u)][{1}NeuAc(a2-u)][{1}HSO3(u1-u)]{0}GlcNAc(b1-6)][{1}NeuAc(u2-6)][{6}Gal(b1-6)][{1}GalNAc(a1-3)][{1}Gal(a1-3)][{1}GlcNAc(b1-3){1}Gal(b1-u){1}GlcNAc(b1-3)[{1}NeuAc(a2-3)]{2}Gal(b1-u)[{3}HSO3(u1-6)][{1}NeuAc(a2-6)][{1}Fuc(a1-4)][{11}Fuc(a1-2)[{1}GalNAc(a1-3)[{2}NeuAc(a2-6)]{2}Gal(b1-3)[{2}GalNAc(a1-3)[{1}NeuAc(a2-6)]{6}Gal(b1-4)]{11}GlcNAc(b1-6)][{5}NeuAc(a2-6)][{2}HSO3(u1-6)][{1}GalNAc(a1-3)][{8}NeuAc(a2-3)][{1}HSO3(u1-3)][{2}Fuc(a1-2)[{2}NeuAc(a2-6)][{4}GalNAc(a1-3)]{6}Gal(b1-3)[{3}Fuc(a1-2)[{1}HSO3(u1-6)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-4){1}GlcNAc(b1-3)][{5}GalNAc(a1-3)]{13}Gal(b1-4)]{21}GlcNAc(b1-3)]{61}Gal(b1-4)][{14}Fuc(a1-2)[{1}HSO3(u1-6)][{1}GlcNAc(b1-3)][{2}GalNAc(a1-3)]{24}Gal(b1-3)][{12}Fuc(a1-3)]{0}GlcNAc(b1-3)]{0}GalNAc
hsa00601 {2}Fuc(a1-u)[{2}NeuAc(a2-6)][{2}Gal(b1-u)]{0}GlcNAc(b1-3)[{4}Fuc(a1-3)[{3}Gal(b1-3)[{1}Fuc(a1-4)][{1}Gal(b1-4)][{1}Fuc(a1-3)]{4}GlcNAc(b1-3)[{1}NeuAc(a2-6)]{9}Gal(b1-4)]{9}GlcNAc(b1-6)]{0}Gal(b1-4){0}Glc
hsa00602 {1}NeuAc(a2-6){0}Gal(b1-4){0}GlcNAc(b1-3){0}Gal(b1-4){0}Glc
hsa00532 {2}HSO3(u1-3)[{3}delta4,5GlcA(b1-3)[{1}HSO3(u1-6)][{1}HSO3(u1-4)]{0}GalNAc(b1-4)]{0}GlcA(b1-3){0}Gal(b1-3)[{1}NeuAc(a2-6)][{1}NeuAc(a2-3)]{0}Gal(b1-4){0}Xyl
hsa00510 {2}GlcNAc(b1-u)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-2)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-6)]{1}Man(b1-6)][{2}Man(a1-2){7}Man(a1-u)[{1}Fuc(a1-2){1}Gal(b1-u)[{1}NeuAc(a2-u)[{6}GalNAc(b1-4)][{1}Neu5,9Ac2(a2-3)][{37}NeuAc(a2-3)][{1}NeuAc2(a2-3)][{13}NeuAc(a2-3){21}Gal(b1-4){21}GlcNAc(b1-3)][{2}Fuc(a1-2)][{2}Gal(b1-4){2}GlcNAc(b1-u)][{1}NeuGc(a2-u)]{144}Gal(b1-4)][{3}GalNAc(b1-4)][{3}Fuc(a1-3)]{0}GlcNAc(b1-6)][{4}H2PO3(u1-6){0}Man(a1-2){0}Man(a1-6)][{2}Gal(b1-4){2}GlcNAc(b1-3)][{3}Man(a1-2){0}Man(a1-3)][{1}Fuc(a1-2){1}Gal(b1-u)[{2}HSO3(u1-4)[{1}NeuAc(a2-6)]{17}GalNAc(b1-4)][{2}NeuGc(a2-u)[{3}NeuAc(a2-6)][{2}Fuc(a1-6)][{8}GalNAc(b1-4)][{8}HSO3(u1-3)][{2}Neu5,9Ac2(a2-3)][{1}NeuGc(a2-3)][{81}NeuAc(a2-3)][{13}Gal(a1-3)][{4}GalNAc(a1-3)][{3}Fuc(a1-3)[{1}Fuc(a1-2)[{11}NeuAc(a2-3)]{26}Gal(b1-4)]{26}GlcNAc(b1-3)][{2}Gal(b1-3)][{18}Fuc(a1-2)][{5}NeuAc(a2-u)]{0}Gal(b1-4)][{18}Fuc(a1-3)][{1}Fuc(a1-2)]{0}GlcNAc(b1-2)][{2}NeuAc(u2-3){4}Gal(u1-4){4}GlcNAc(u1-2)][{4}NeuAc(a2-u){8}Gal(b1-4){8}{GlcNAc(b1-3){8}Gal(b1-4){8}}jGlcNAc(b1-2)][{2}NeuAc(u2-u)[{2}NeuAc(a2-u)]{43}Gal(u1-u)[{32}Gal(b1-4)][{2}NeuAc(a2-u){2}Gal(b1-u)]{82}GlcNAc(u1-u)][{1}NeuAc(a2-3)[{1}NeuAc(a2-6)]{7}Gal(b1-u)[{2}NeuAc(a2-6){2}GalNAc(b1-4)][{5}Fuc(a1-2)[{1}NeuAc(a2-6)][{3}NeuAc(a2-3)][{2}GalNAc(a1-3)][{2}Gal(b1-4){2}GlcNAc(b1-3)]{22}Gal(b1-4)]{37}GlcNAc(b1-u)][{6}Man(u1-u)]{0}Man(a1-6)][{33}GlcNAc(b1-4)][{20}GlcNAc(u1-4)][{1}HexNAc(b1-4)][{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-2)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-4)]{1}Man(b1-3)][{3}NeuAc(u2-u)[{2}NeuAc(a2-u)]{43}Gal(u1-u)[{31}Gal(b1-4)][{2}NeuAc(a2-u){3}Gal(b1-u)]{83}GlcNAc(u1-u)[{1}Fuc(a1-2)[{1}NeuAc(a2-6)]{4}Gal(b1-4){6}GlcNAc(b1-6)][{1}Fuc(a1-2){1}Gal(b1-u)[{1}HSO3(u1-6)][{3}NeuAc(a2-u)[{2}NeuAc(a2-6)][{1}GlcNAc(b1-4)][{7}GalNAc(b1-4)][{2}NeuAc(a2-3){2}Gal(b1-4){2}GlcNAc(b1-3)][{2}Neu5,9Ac2(a2-3)][{51}NeuAc(a2-3)][{18}HSO3(u1-3)][{3}Gal(a1-3)][{5}Fuc(a1-2)][{1}NeuGc(a2-u)]{185}Gal(b1-4)][{2}Gal(b1-3)][{14}Fuc(a1-3)]{0}GlcNAc(b1-4)][{4}NeuAc(a2-u){8}Gal(b1-4){8}{GlcNAc(b1-3){8}Gal(b1-4){8}}kGlcNAc(b1-2)][{2}NeuAc(u2-3){4}Gal(u1-4){4}GlcNAc(u1-2)][{3}H2PO3(u1-6){0}Man(a1-2)][{3}Fuc(a1-2)[{1}GalNAc(a1-3)][{1}Gal(a1-3)]{5}Gal(b1-u)[{9}HSO3(u1-4)[{9}NeuAc(a2-6)]{40}GalNAc(b1-4)][{2}NeuGc(a2-u)[{3}NeuAc(a2-6)][{1}GalNAc(b1-4)][{23}HSO3(u1-3)][{6}Gal(a1-3)][{1}NeuGc(a2-3)][{2}Neu5,9Ac2(a2-3)][{11}GalNAc(a1-3)][{1}NeuAc(a2-3)[{1}NeuAc(a2-6)]{7}Gal(b1-4){7}GlcNAc(b1-3)][{65}NeuAc(a2-3)][{30}Fuc(a1-2)][{8}NeuAc(a2-u)]{0}Gal(b1-4)][{1}Gal(b1-3)][{14}Fuc(a1-3)][{4}Fuc(a1-u)]{0}GlcNAc(b1-2)][{1}NeuAc(a2-3)[{1}NeuAc(a2-6)]{7}Gal(b1-u)[{1}NeuAc(a2-6){1}GalNAc(b1-4)][{2}NeuAc(a2-3)[{1}NeuAc(a2-6)]{11}Gal(b1-4)]{26}GlcNAc(b1-u)][{2}Man(u1-u)]{0}Man(a1-3)][{5}Xyl(b1-2)][{1}Gal(b1-u)[{1}Fuc(a1-3)]{1}GlcNAc(u1-u)[{2}NeuAc(a2-u)][{2}NeuAc(u2-u)]{39}Gal(u1-u)[{18}Gal(b1-4)][{1}Fuc(a1-3)][{1}Fuc(a1-u)][{1}Gal(b1-u)][{2}Fuc(u1-u)]{64}GlcNAc(u1-u)[{5}Man(a1-6)][{4}NeuAc(a2-u){25}Gal(b1-4){31}GlcNAc(b1-6)][{1}NeuAc(u2-3){1}Gal(u1-4){1}GlcNAc(u1-4)][{2}Gal(b1-u)[{3}NeuAc(a2-u)[{1}NeuAc(a2-3)]{31}Gal(b1-4)][{2}Fuc(a1-3)]{34}GlcNAc(b1-4)][{5}Man(a1-3)][{4}NeuAc(u2-3){6}Gal(u1-4){6}GlcNAc(u1-2)][{1}Man(a1-2){3}Man(a1-2)][{1}Fuc(a1-u)[{3}NeuGc(a2-u)[{18}NeuAc(a2-6)][{1}HSO3(u1-6)][{4}Gal(b1-4){4}GlcNAc(b1-3)][{16}NeuAc(a2-3)][{1}Neu5,9Ac2(a2-3)][{1}GalNAc(a1-3)][{4}Fuc(a1-2)][{13}NeuAc(a2-u)]{179}Gal(b1-4)][{1}NeuAc(a2-u)[{8}NeuAc(a2-6)][{2}HSO3(u1-4)]{35}GalNAc(b1-4)][{13}Fuc(a1-3)][{1}NeuAc(a2-6){2}Gal(u1-u)][{2}Gal(b1-u)]{246}GlcNAc(b1-2)][{4}Gal(b1-4){4}{GlcNAc(b1-3){4}Gal(b1-4){4}}kGlcNAc(b1-2)][{4}NeuAc(a2-u){4}Gal(b1-4){4}{GlcNAc(b1-3){4}Gal(b1-4){4}}jGlcNAc(b1-2)][{1}HexNAc(u1-u)][{1}NeuAc(a2-u)[{4}NeuAc(a2-6)][{2}NeuAc(a2-3)]{21}Gal(b1-u)[{1}NeuAc(a2-3){2}Gal(b1-4){2}GlcNAc(b1-3)[{8}NeuAc(a2-3)]{25}Gal(b1-4)][{4}GalNAc(b1-4)][{1}Gal(b1-3)]{61}GlcNAc(b1-u)][{4}Man(u1-u)][{3}Man(a1-u)[{1}Man(a1-2)]{23}Man(a1-u)]{438}Man(a1-u)][{2}GlcNAc(u1-u)]{0}Man(b1-4)[{1}Man(a1-2){1}Man(a1-u)[{1}Man(a1-2)]{1}Man(a1-u)[{1}Fuc(a1-2){1}Gal(b1-u){1}GlcNAc(b1-2){1}Man(a1-6)][{1}GlcNAc(b1-4)][{1}Fuc(a1-2){1}Gal(b1-u){1}GlcNAc(b1-2)[{1}Fuc(a1-2){1}Gal(b1-u){1}GlcNAc(b1-4)]{1}Man(a1-2)]{2}Man(a1-4)]{0}GlcNAc(b1-4){0}GlcNAc
__GLYCOSUITE_RESULTS__

unmatched_glycomedb_results = <<__UNMATCHED_GLYCOMEDB__
dglcp {1}Fuc(a1-u)[{5}Fuc(a1-6)][{1}Glc(a1-6){1}Glc(b1-6)][{4}Thr(a1-4)][{1}Glc(a1-6){1}Glc(a1-4)[{1}Glc(a1-6){1}Glc(a1-6)]{2}Glc(a1-4)[{1}Glc(a1-6){1}Glc(a1-4)[{1}Glc(a1-6)]{2}Glc(a1-4)[{1}Glc(a1-6)]{3}Glc(a1-4)[{1}Glc(a1-4){1}Glc(a1-6)]{7}Glc(a1-6)]{9}Glc(a1-4)[{1}Glc(a1-6)]{9}Glc(a1-4)][{1}Fuc(a1-2){1}Gal(b1-3){1}GalNAc(b1-3)[{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-6)]{2}Gal(a1-4)][{1}Gal(b1-3){1}GlcNAc(b1-4){1}Glc(b1-4)][{1}Gal(u1-3)[{1}NeuAc(u2-4)]{1}GlcNAc(u1-3)[{1}Fuc(u1-2){1}Gal(u1-3){1}GlcNAc(u1-6)]{1}Glc(u1-4)][{2}Fuc(a1-4)][{1}NeuAc(a2-3){1}Gal(b1-3)[{1}Fuc(a1-4)][{4}Gal(b1-4){5}GlcNAc(b1-2)[{2}Gal(b1-4){2}GlcNAc(b1-4)]{6}Man(a1-3)[{4}Gal(b1-4){5}GlcNAc(b1-2)[{1}Man(a1-6)][{1}Gal(b1-4){1}GlcNAc(b1-6)][{1}Man(a1-3)]{6}Man(a1-6)]{6}Man(b1-4)]{7}GlcNAc(b1-4)][{1}Fuc(u1-u)[{1}Gal(b1-6)][{2}NeuAc(a2-6)][{1}NeuAc(u2-6)][{1}Fuc(a1-3)[{1}NeuAc(a2-u){2}Gal(b1-4)]{3}GlcNAc(b1-6)][{1}Fuc(a1-6)][{1}NeuAc(a2-u)[{1}NeuAc(a2-u){1}Gal(b1-4)][{1}Fuc(a1-3)][{1}NeuAc(a2-3){2}Gal(b1-3)]{4}GlcNAc(b1-4)][{1}Fuc(a1-2){1}Gal(b1-3){1}GalNAc(b1-3){2}Gal(b1-4)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)][{2}NeuAc(a2-3)]{3}Gal(b1-4){3}GlcNAc(b1-3)[{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-6)][{1}NeuAc(a2-3)]{5}Gal(b1-3)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|4acetyl|5n-glycolyl(a2-3)][{2}GlcA(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3)[{2}Fuc(a1-2)[{1}GalNAc(b1-4)][{1}Gal(a1-3)][{1}NeuAc(a2-3){1}Gal(b1-4){1}GalNAc(b1-3)][{1}NeuAc(a2-3){1}Gal(b1-4){1}GlcNAc(b1-3)][{1}NeuAc(a2-3)]{5}Gal(b1-4)][{1}NeuAc(a2-3)][{1}DFuc(a1-2)[{1}NeuAc(a2-3){1}Gal(b1-3){1}GalNAc(a1-3)]{2}Gal(b1-3)]{10}GalNAc(b1-3)][{1}NeuGc(a2-8)[{1}NeuAc(a2-8)]{3}NeuGc(a2-3)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-3){3}GalNAc(a1-3)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5amino(a2-3)][{1}GalNAc(b1-3){3}Gal(a1-3)][{1}Fuc(b1-3)][{9}Fuc(a1-2)][{1}NeuAc(a2-u){1}Gal(b1-4){1}GlcNAc(b1-u)][{1}hex-x:x(u1-u)][{1}NeuAc(a2-u){3}NeuAc(a2-u)]{58}Gal(b1-4)][{3}Fuc(a1-u){3}Gal(u1-u)[{2}Fuc(a1-u)]{3}GlcNAc(u1-u){3}Gal(u1-u)[{1}Fuc(a1-u)][{1}Fuc(u1-u)]{3}GlcNAc(u1-u)[{1}Gal(u1-3){1}GlcNAc(u1-6)][{1}NeuAc(a2-3){1}Gal(b1-3)[{1}NeuAc(a2-6)][{2}NeuAc(u2-4)][{2}Gal(u1-3)]{3}GlcNAc(u1-3)]{7}Gal(u1-4)][{1}Xyl(a1-3){1}Xyl(a1-3)][{10}Fuc(a1-3)][{3}Fuc(a1-2)[{1}NeuAc(a2-3)[{1}NeuAc(a2-3){1}Gal(b1-4)]{1}GalNAc(b1-3)][{1}Gal(a1-3)][{1}Fuc(a1-3)[{1}Fuc(a1-3)[{1}NeuAc(a2-3){2}Gal(b1-4)]{2}GlcNAc(b1-3){2}Gal(b1-4)]{2}GlcNAc(b1-3){2}Gal(b1-4){2}GlcNAc(b1-3)][{1}Gal(b1-3)][{1}GalNAc(a1-3)]{7}Gal(b1-3)][{1}Fuc(a1-2)][{2}Xyl(u1-u){3}Xyl(u1-u)][{1}Fuc(a1-u)[{1}Fuc(a1-u)[{1}Fuc(a1-3)[{1}Fuc(a1-2)[{1}Gal(a1-3)]{1}Gal(b1-4)]{1}GlcNAc(b1-u){1}Gal(b1-u){1}GlcNAc(b1-u)]{3}Gal(b1-u)]{3}GlcNAc(b1-u)[{1}NeuAc(a2-u){1}Gal(b1-u){1}GalNAc(b1-u){1}Gal(a1-u)]{4}Gal(b1-u)][{1}Fuc(u1-u)]{109}Glc
dxylf {1}GalNAc(a1-u){2}GlcA(b1-u)[{2}GlcA(b1-4)][{1}Xyl(b1-4)][{1}Gal(b1-3)][{1}Thr(a1-u)[{1}Thr(a1-3)[{1}GlcA(b1-3)]{2}GalNAc(b1-4){2}GlcA(b1-u)]{3}Gal(b1-u){3}Gal(b1-u)][{1}NeuAc(a2-u)]{10}Xyl
dgalp|2nac {1}NeuAc(u2-u){1}Gal(u1-u)[{1}GalNAc(a1-6)][{1}Gal(b1-4){1}GalNAc(b1-6)][{1}Gal(b1-6)][{2}NeuGc(a2-6)][{1}Thr(a1-4)][{1}Fuc(a1-3)[{1}NeuAc(a2-3){1}Gal(b1-4)]{1}GlcNAc(b1-3){3}Gal(b1-4)][{1}NeuAc(a2-u){5}GalNAc(a1-3)][{1}NeuAc(a2-6){4}Gal(a1-3)][{2}Gal(u1-4){2}GlcNAc(u1-3)][{3}IdoA(a1-3)][{1}GalNAc(b1-4){5}GlcA(b1-3)][{1}NeuAc(a2-3)[{1}Gal(b1-4){1}GlcNAc(b1-6)][{2}GlcNAc(u1-3)][{1}Gal(b1-4){1}GlcNAc(b1-3)]{4}Gal(u1-3)][{1}Fuc(a1-3)][{6}Thr(a1-3)][{1}GalNAc(b1-3)][{1}NeuAc(a2-u)][{1}NeuAc(u2-u)]{43}GalNAc
dgalp {2}NeuAc(a2-u)[{4}Fuc(a1-6)][{1}NeuGc(a2-6)][{1}Fuc(a1-3)[{2}Fuc(a1-2)[{1}NeuAc(a2-3)]{12}Gal(b1-4)][{1}Fuc(a1-2){3}Gal(b1-3)]{18}GlcNAc(b1-6)][{1}Gal(a1-6)][{3}NeuAc(a2-6)][{1}NeuAc(a2-u){1}GalNAc(a1-6)][{4}Fuc(a1-2)[{2}GalNAc(a1-3)][{1}Gal(a1-3)]{5}Gal(b1-3)[{1}Fuc(a1-6)][{3}Fuc(a1-4)][{1}Gal(b1-4)]{7}GlcNAc(b1-4)][{1}Gal(b1-3){3}GalNAc(b1-4)][{1}GalNAc(b1-3){3}Gal(a1-4)][{3}Fuc(a1-2)[{1}GalNAc(b1-4)][{1}GalNAc(a1-3)][{1}Gal(a1-3)]{5}Gal(b1-4)][{1}NeuAc(a2-u){1}NeuAc(a2-3){1}Gal(u1-3){1}Gal(u1-3)][{1}GalNAc(b1-3)][{3}Fuc(a1-3)][{5}Gal(a1-3)][{15}Fuc(a1-3)[{1}Fuc(a1-3)[{2}Gal(b1-4)]{2}GlcNAc(b1-3){2}Glc(b1-4)][{8}Fuc(a1-4)][{1}Fuc(a1-2){1}Gal(b1-4){1}GlcNAc(b1-u)[{2}Fuc(a1-2){4}Gal(b1-4){6}GlcNAc(b1-6)][{2}NeuAc(a2-6)][{3}GalNAc(b1-4)][{1}dgro-dgal-non-2:6|1:a|2:keto|3:d|5amino(a2-3)][{5}Fuc(a1-3)[{2}Fuc(a1-2)[{4}NeuAc(a2-3)]{13}Gal(b1-4)]{18}GlcNAc(b1-3)][{9}NeuAc(a2-3)][{3}Fuc(a1-2)]{43}Gal(b1-4)][{5}Fuc(a1-2)[{3}GalNAc(a1-3)][{1}Gal(a1-3)][{3}NeuAc(a2-3)]{14}Gal(b1-3)]{65}GlcNAc(b1-3)][{1}NeuAc(a2-3)[{1}GalNAc(b1-4)]{1}Gal(b1-3){4}GalNAc(a1-3)][{4}NeuAc(a2-3)][{1}Gal(b1-3){1}Gal(b1-3)][{1}Glc(b1-2)][{7}Fuc(a1-2)][{1}Glc(u1-u)][{2}Fuc(a1-3)[{1}Fuc(a1-2)[{1}Gal(a1-3)]{2}Gal(b1-4)]{2}GlcNAc(b1-u)]{120}Gal
lgalp|6d {1}NeuAc(a2-6){1}Gal(b1-4){1}GlcNAc(b1-3)[{1}Glc(b1-3)]{4}Fuc
dglcp|6a {1}GlcNAc(b1-4){2}GlcA(b1-3){3}GlcNAc(b1-4){4}GlcA(b1-3){5}GlcNAc(b1-4){6}GlcA(b1-3){6}GlcNAc(b1-4)[{1}Glc(a1-4)][{1}GlcNAc(a1-4)]{10}GlcA
dneu|1a|2keto|3d|5nac {2}NeuAc(a2-8){3}NeuAc
dmanp {2}Fuc(a1-3)[{1}NeuAc(a2-6){1}GalNAc(b1-4)][{2}Fuc(a1-2)[{1}NeuAc(a2-6)][{1}Fuc(a1-2){2}Gal(b1-3)[{1}Gal(b1-4)]{3}GlcNAc(b1-3)]{9}Gal(b1-4)][{2}Fuc(a1-4)][{2}Fuc(a1-2){5}Gal(b1-3)]{15}GlcNAc(b1-u)[{1}Gal(b1-4){1}GlcNAc(b1-6)][{2}Fuc(a1-3)[{1}Gal(a1-3)[{1}NeuAc(a2-6)]{11}Gal(b1-4)]{13}GlcNAc(b1-2)[{2}Gal(b1-4){4}GlcNAc(b1-6)]{16}Man(a1-6)][{2}GlcNAc(b1-4)][{1}Gal(b1-4)][{1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-4)][{2}Fuc(a1-3)[{1}NeuAc(a2-6){9}Gal(b1-4)]{12}GlcNAc(b1-2)[{4}Gal(b1-4){4}GlcNAc(b1-4)]{13}Man(a1-3)][{1}Fuc(a1-2)][{1}Man(a1-2)][{4}Fuc(a1-3)[{1}GalNAc(b1-4)][{5}Gal(b1-4)]{8}GlcNAc(b1-2)][{1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-1)][{1}NeuAc(a2-3){1}Gal(b1-3){1}GlcNAc(b1-u){3}Man(a1-u)]{47}Man
dglcp|2nac {5}Fuc(a1-2)[{1}NeuAc(a2-3)][{1}Gal(a1-3)][{3}GalNAc(a1-3)][{1}Gal(b1-3)[{1}Fuc(a1-4)]{1}GlcNAc(b1-3)]{7}Gal(b1-u)[{1}Gal(b1-4){1}GlcNAc(b1-6)][{9}Fuc(a1-6)][{5}NeuAc(a2-6)][{1}Gal(b1-6)][{1}NeuAc(a2-u)[{1}Fuc(a1-2){4}Gal(b1-4){6}GlcNAc(b1-6)][{4}NeuAc(a2-6)][{2}GalNAc(b1-4)][{2}Gal(a1-4)][{2}NeuAc(a2-8){12}NeuAc(a2-3)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)]{1}Gal(b1-3){6}GalNAc(a1-3)][{3}Gal(a1-3)][{1}Fuc(a1-2)[{1}GalNAc(a1-3)][{2}NeuAc(a2-3)]{6}Gal(b1-3)[{5}Fuc(a1-4)][{1}NeuAc(a2-u)[{6}NeuAc(a2-6)][{10}NeuAc(a2-3)][{1}Fuc(a1-3)[{1}NeuAc(a2-3){1}Gal(b1-4)]{1}GlcNAc(b1-3)]{32}Gal(b1-4)][{9}Fuc(a1-3)]{40}GlcNAc(b1-3)][{1}lxyl-hex-1:5|4:d|6:d(a1-2)][{15}Fuc(a1-2)][{1}lxyl-hex-1:5|3:d|6:d(a1-2)][{1}llyx-hex-1:5|2:d|6:d(a1-2)]{99}Gal(b1-4)][{1}Fuc(a1-2){15}Fuc(a1-4)][{2}GlcNAc(b1-2){2}Man(a1-3)[{4}NeuAc(a2-3)[{2}NeuAc(a2-6)]{6}Gal(b1-4){6}GlcNAc(b1-2){6}Man(b1-6)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-6)][{2}GlcNAc(b1-4)][{2}NeuAc(a2-3)[{4}NeuAc(a2-6)]{6}Gal(b1-4){6}GlcNAc(b1-2){6}Man(b1-3)]{8}Man(a1-4)][{3}Gal(b1-4){3}GlcNAc(b1-2)[{3}Gal(b1-4){3}GlcNAc(b1-4)]{3}Man(a1-3)[{2}NeuAc(a2-6){2}Gal(b1-4)[{2}Fuc(a1-6)]{2}GlcNAc(u1-2)[{1}NeuAc(a2-6){1}Gal(b1-4)[{1}Fuc(a1-6)]{1}GalNAc(u1-2)]{3}Man(u1-6)]{3}Man(u1-4)][{1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-3)[{1}Gal(b1-4){1}GlcNAc(b1-2){1}Man(a1-6)]{1}Glc(b1-4)][{5}GalNAc(b1-4)][{1}Fuc(a1-2){1}dxyl-hex-1:5|4:d(b1-4)][{1}NeuAc(b2-3)[{1}NeuAc(b2-6)]{1}Gal(b1-4){1}GlcNAc(b1-u)[{1}NeuAc(a2-6){1}Gal(b1-4){1}GlcNAc(b1-2)]{1}Man(b1-u)[{3}NeuAc(a2-6){3}Gal(b1-4){3}GlcNAc(b1-2)[{2}Man(a1-2){2}Man(a1-6)][{4}Man(a1-3)]{7}Man(b1-6)][{2}NeuAc(a2-3)[{2}NeuAc(a2-6)]{4}Gal(b1-4){4}GlcNAc(b1-2){4}Glc(a1-6)][{2}NeuAc(a2-6)][{1}Fuc(a1-3)[{1}Gal(b1-4)]{1}GlcNAc(b1-u)[{22}Man(a1-2){53}Man(a1-6)][{2}Man(a1-2){2}Man(b1-6)][{8}NeuAc(a2-3)[{2}NeuAc(a2-6)][{4}Gal(b1-4){4}GlcNAc(b1-3)]{35}Gal(b1-4)[{2}Glc(b1-4)]{37}GlcNAc(b1-6)][{1}NeuAc(a2-u)[{1}NeuAc(a2-3)]{2}Gal(b1-4){6}GlcNAc(b1-4)][{26}Man(a1-2){63}Man(a1-3)][{3}Fuc(a1-3)[{2}Gal(b1-4){2}GlcNAc(b1-4)][{2}NeuAc(a2-u)[{29}NeuAc(a2-6)][{2}Gal(b1-6)][{2}Gal(b1-4){2}GlcNAc(b1-3){15}Gal(b1-4){15}GlcNAc(b1-3)][{19}NeuAc(a2-3)][{1}DFuc(a1-2)][{1}Fuc(a1-2)]{118}Gal(b1-4)]{136}GlcNAc(b1-2)][{1}GlcNAc(b1-4){1}Gal(b1-2)]{224}Man(a1-6)][{1}GlcNAc(u1-4)][{7}GlcNAc(b1-4)][{1}Fuc(a1-3)[{1}Gal(b1-4)]{1}GlcNAc(b1-u)[{1}Gal(b1-4){1}GlcNAc(b1-3){1}Gal(b1-4){1}GlcNAc(b1-6)][{2}Fuc(a1-3)[{3}NeuAc(a2-u)[{11}NeuAc(a2-6)][{4}Gal(b1-4){4}GlcNAc(b1-3)][{14}NeuAc(a2-3)]{56}Gal(b1-4)]{62}GlcNAc(b1-4)][{1}GlcNAc(b1-4){1}Gal(b1-2)][{2}Glc(a1-2){2}Glc(a1-3){4}Glc(a1-3){26}Man(a1-2){45}Man(a1-2)][{1}NeuAc(b2-u){2}Gal(b1-u)[{8}NeuAc(a2-u)[{46}NeuAc(a2-6)][{2}Gal(b1-4){2}GlcNAc(b1-3){15}Gal(b1-4){15}GlcNAc(b1-3)][{19}NeuAc(a2-3)][{1}DFuc(a1-2)][{1}Fuc(a1-2)]{133}Gal(b1-4)][{3}Fuc(a1-3)][{1}Gal(u1-u)]{155}GlcNAc(b1-2)]{235}Man(a1-3)][{1}NeuAc(b2-3)[{2}NeuAc(a2-6)]{5}Gal(b1-4){5}GlcNAc(b1-2)[{2}NeuAc(a2-3)[{1}NeuAc(b2-6)]{3}Gal(b1-4){3}GlcNAc(b1-4)]{5}Man(b1-3)][{4}NeuAc(a2-3){4}Gal(b1-4){4}GlcNAc(b1-2){4}Glc(a1-3)][{1}Fuc(a1-3)[{1}Gal(b1-4){1}GlcNAc(b1-3){2}Gal(b1-4)]{2}GlcNAc(b1-u)[{2}Gal(b1-4){2}GlcNAc(b1-6)][{2}Gal(b1-4){3}GlcNAc(b1-4)][{1}Fuc(a1-3)[{1}Gal(b1-4){1}GlcNAc(b1-3){6}Gal(b1-4)]{7}GlcNAc(b1-2)]{8}Man(a1-u)]{282}Man(b1-4)][{1}Gal(a1-4)][{2}NeuAc(a2-3){2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-3)[{2}NeuAc(a2-3){2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-6)]{2}Man(b1-4){2}GlcNAc(u1-4)][{3}Thr(a1-4)][{2}NeuAc(a2-7){2}NeuAc(a2-3){2}Gal(u1-3){2}Gal(u1-4)][{1}Fuc(a1-2){1}Ara(a1-3)][{1}GlcA(b1-3){2}GlcNAc(b1-4){3}GlcA(b1-3){4}GlcNAc(b1-4){5}GlcA(b1-3){6}GlcNAc(b1-4){7}GlcA(b1-3)][{3}Fuc(a1-3){35}Fuc(a1-3)][{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-3)[{2}Gal(b1-4){2}GlcNAc(b1-2){2}Man(a1-6)]{2}Man(b1-4){2}GlcNAc(b1-3)][{14}Fuc(a1-2)[{2}NeuAc(a2-6){2}Gal(b1-6)][{1}Gal(b1-4){1}GlcNAc(b1-6)][{1}Gal(a1-3)][{1}Fuc(a1-3)[{1}Fuc(a1-2){1}Gal(b1-4)][{1}Gal(b1-3)]{2}GlcNAc(b1-3)][{2}NeuAc(a2-9){7}NeuAc(a2-3)][{6}GalNAc(a1-3)]{37}Gal(b1-3)][{1}Fuc(b1-3)][{1}Fuc(a1-2){1}dxyl-hex-1:5|3:d(b1-3)][{1}Fuc(a1-u)]{473}GlcNAc
lidop|6a {1}Glc(a1-4){1}IdoA
__UNMATCHED_GLYCOMEDB__

unmatched_glycosuite_results = <<__UNMATCHED_GLYCOSUITE__
dglcp {2}Xyl(u1-u)[{6}Fuc(a1-3)[{1}Fuc(a1-2)[{5}Fuc(a1-3)[{3}Fuc(a1-2){5}Gal(b1-4)]{5}GlcNAc(b1-3)]{7}Gal(b1-4)]{7}GlcNAc(b1-4)][{1}NeuAc(a2-3){1}Man(b1-4)][{2}Fuc(a1-2)[{1}NeuAc(a2-6)]{5}Gal(b1-4)][{1}Fuc(a1-2){1}Gal(b1-3)[{1}NeuAc(a2-6)]{1}GlcNAc(b1-3){1}Gal(b1-3)][{4}Fuc(a1-3)][{4}Fuc(a1-3)[{1}Fuc(a1-2)[{3}Fuc(a1-3)[{2}Fuc(a1-2){3}Gal(b1-4)]{3}GlcNAc(b1-3)]{5}Gal(b1-4)]{5}GlcNAc(b1-3)]{22}Glc
dgalp {1}NeuAc(u2-3)[{1}NeuAc(a2-3){1}Gal(b1-3)[{1}Fuc(a1-4)]{1}GlcNAc(b1-3)][{1}NeuAc(a2-3)]{4}Gal
dgalp|2nac {1}NeuAc(a2-u)[{3}NeuAc(u2-6)][{2}Fuc(u1-u)[{1}Gal(u1-4)][{1}NeuAc(u2-u){5}Gal(u1-u)]{8}GlcNAc(u1-6)][{1}Fuc(u1-u)[{1}NeuAc(a2-3)][{1}NeuAc(u2-3){1}Gal(u1-u)[{1}Fuc(u1-4)][{1}NeuAc(u2-3){1}Gal(u1-3)]{3}GlcNAc(u1-3)][{6}NeuAc(u2-u)][{1}Fuc(u1-u){6}Gal(u1-u)[{3}Fuc(u1-u)]{7}GlcNAc(u1-u)]{24}Gal(u1-3)][{1}Gal(u1-4){1}GlcNAc(u1-3)][{1}GalNAc(a1-3)][{1}NeuAc(a2-3){1}Gal(u1-6){1}GlcNAc(b1-u){1}GlcNAc(b1-u){1}Gal(b1-u)[{2}NeuAc(a2-u)]{6}Gal(b1-u)][{1}NeuAc(u2-u){1}Gal(u1-u){1}GalNAc(u1-u)][{1}Fuc(a1-u)][{1}NeuAc(u2-u)][{1}Fuc(a1-3)[{2}NeuAc(a2-3){2}Gal(b1-3)[{2}Fuc(a1-4)]{2}GlcNAc(b1-3){2}Gal(b1-4)]{2}GlcNAc(b1-u)][{7}NeuAc(u2-u)[{1}NeuAc(a2-u){1}Gal(b1-u){1}GlcNAc(b1-u)][{1}Gal(b1-u){1}GlcNAc(u1-u)]{14}Gal(u1-u)][{2}Fuc(u1-u)[{1}Gal(u1-u){1}GlcNAc(u1-u)]{4}Gal(u1-u)[{2}Fuc(u1-u)]{4}GlcNAc(u1-u){5}Gal(u1-u)[{2}Fuc(u1-u)]{7}GlcNAc(u1-u)]{51}GalNAc
lgalp|6d {1}Glc(u1-u)[{1}NeuAc(a2-6){1}Gal(b1-4){1}GlcNAc(b1-3)][{1}Glc(b1-3)]{4}Fuc
dneu|1a|2keto|3d|5nac {1}NeuAc(a2-8){2}NeuAc
dmanp {1}Man(u1-2){1}Man(u1-2){1}Man(u1-2){1}Man(u1-2)[{1}H2PO3(u1-u){1}Man(a1-6)][{1}Man(b1-2){1}Man(b1-2){2}Man(a1-2)[{1}Man(b1-2){1}Man(b1-2)]{4}Man(a1-2){5}Man(a1-2)]{7}Man
dglcp|2nac {2}Fuc(u1-u)[{2}Fuc(a1-6)][{1}Fuc(a1-2)[{1}NeuAc(a2-6)][{1}NeuAc(a2-3)[{1}NeuAc(a2-6)]{2}Gal(b1-4){2}GlcNAc(b1-3)][{1}NeuAc(a2-8){2}NeuAc(a2-3)]{9}Gal(b1-4)][{2}NeuAc(a2-u)[{1}NeuAc(a2-u){1}Gal(b1-4){1}GlcNAc(b1-3)]{2}Gal(b1-4){2}GlcNAc(b1-u)[{3}NeuAc(a2-u)[{2}NeuAc(a2-u){2}Gal(b1-4){2}GlcNAc(b1-3)]{4}Gal(b1-4){4}GlcNAc(b1-2)]{4}Man(a1-u)[{1}NeuAc(a2-6)][{2}Fuc(a1-3)[{2}NeuAc(a2-u)[{1}Gal(b1-6)][{6}NeuAc(a2-6)][{7}NeuAc(a2-3)]{25}Gal(b1-4)]{28}GlcNAc(b1-2)[{3}NeuAc(a2-3){3}Gal(b1-4){3}GlcNAc(b1-6)][{1}Fuc(a1-3)[{1}Gal(b1-4)]{1}GlcNAc(b1-4)][{1}Man(a1-2)]{33}Man(a1-6)][{1}GlcNAc(b1-4)][{1}NeuAc(a2-u){1}Gal(b1-4){1}GlcNAc(b1-u)[{1}Fuc(a1-3)[{2}NeuAc(a2-u)[{1}NeuAc(a2-6)][{6}NeuAc(a2-3)]{17}Gal(b1-4)]{18}GlcNAc(b1-4)][{2}Fuc(a1-3)[{5}NeuAc(a2-u)[{10}NeuAc(a2-6)][{4}NeuAc(a2-3)]{29}Gal(b1-4)]{32}GlcNAc(b1-2)][{1}Man(a1-2){1}Man(a1-2)]{35}Man(a1-3)][{1}Man(a1-3)[{1}Man(a1-6)]{1}Man(b1-4){1}GlcNAc(a1-3)]{47}Man(b1-4)][{1}Fuc(a1-4)][{1}Gal(b1-4){1}GlcNAc(b1-2)[{1}Gal(b1-4){1}GlcNAc(b1-4)]{1}Man(a1-3)[{1}Gal(b1-4)[{1}Fuc(a1-6)]{1}GlcNAc(u1-2){1}Man(u1-6)]{1}Man(u1-4)][{1}NeuAc(a2-3){1}Gal(b1-3)][{1}Fuc(a1-3){3}Fuc(a1-3)][{1}Man(u1-3){1}Man(u1-3){1}Man(u1-3){1}Man(u1-u){1}GlcNAc(u1-u){1}GlcNAc(u1-u)][{1}NeuAc(u2-u){1}Gal(b1-u){1}GlcNAc(u1-u)[{1}NeuAc(u2-u){1}Gal(b1-u){1}GlcNAc(b1-u){1}Man(u1-u)]{1}Man(u1-u)[{1}GlcNAc(u1-u)]{1}Man(u1-u)]{63}GlcNAc
__UNMATCHED_GLYCOSUITE__

glycomedb_maps = glycomedb_results.split(/\n/).collect { |line| line.split(/\s/) }
glycosuite_maps = glycosuite_results.split(/\n/).collect { |line| line.split(/\s/) }

glycomedb_unmatched_maps = unmatched_glycomedb_results.split(/\n/).collect { |line| line.split(/\s/) }
glycosuite_unmatched_maps = unmatched_glycosuite_results.split(/\n/).collect { |line| line.split(/\s/) }

opts = {
	:verbose => 5,
	:outfile => nil,
	:test => false,
	:output_directory => 'svgs',
	:min_delta_threshold => 0,
	:delete_sug_a => false,
	:delete_sug_b => false,
	:sug_a_min_hits_threshold => 0,
	:sug_b_min_hits_threshold => 0,
	:normalised_hits_threshold => 0,
	:render_hits_for_all_residues => false,
	:key => nil,
	:use_unmatched => false,
	:always_render_colours => false,
	:scheme => :boston
}

@opts = opts

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby merge_hitmaps.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-o", "--output-directory DIRECTORY", String, "Directory to write results to") { |opts[:output_directory]| }
  opt.on("-c", "--compare",TrueClass, "Run a comparison operation (used to compare hitmaps)") { |compare| opts[:min_delta_threshold] = 0; opts[:delete_sug_a] = false; opts[:delete_sug_b] = false; opts[:normalised_hits_threshold] = 5; opts[:always_render_colours] = true }
  opt.on("-m", "--map",TrueClass, "Generate the composite hitmap") { |compare| opts[:render_hits_for_all_residues] = true; opts[:min_delta_threshold] = 0; opts[:delete_sug_a] = false; opts[:delete_sug_b] = true; opts[:normalised_hits_threshold] = 0; opts[:sug_a_min_hits_threshold] = 5 }
  opt.on("-l", "--label",TrueClass, "Label hits") { |opts[:label_hits_for_residues]| }
  opt.on("-i", "--outline",TrueClass, "Outline hits") { |opts[:render_hit_outlines]| }
  opt.on("-k", "--key KEYNAME",String, "Key to look up structures with") { |opts[:key]| }
  opt.on("-u", "--unmatched",TrueClass) { |opts[:use_unmatched]| }
  opt.on("-t", "--test",TrueClass,"Test run") { |opts[:test]| }  
  opt.on("-p", "--print-keys",TrueClass) { |opts[:print_keys]|
    puts((glycomedb_unmatched_maps.collect { |line| line[0] } + glycosuite_unmatched_maps.collect { |line| line[0] }).sort.uniq.join(','))
    puts((glycomedb_maps.collect { |line| line[0] } + glycosuite_maps.collect { |line| line[0] }).sort.uniq.join(','))
    exit
  }
  opt.on("-s", "--scheme SCHEME",String, "Rendering scheme to use: boston or text") { |scheme| opts[:scheme] = scheme.to_sym }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}

@logger = Logger.new(STDERR)
ActiveRecord::Base.logger = @logger
ActiveRecord::Base.logger.level = opts[:verbose]
DebugLog.global_logger = @logger

class Monosaccharide
  attr_accessor :hits
  attr_accessor :normalised_hits
  attr_accessor :parent_sug
  attr_accessor :delta_hits
end


module ChameleonResidue
  attr_accessor :real_name

  def alternate_name(namespace)
    return name(namespace)
  end

  def name(namespace=nil)
    if namespace.is_a? Symbol
      namespace = NamespacedMonosaccharide::NAMESPACES[namespace]
    end
    return real_name
  end

end

module Sugar::IO::CondensedIupac::Builder

  alias_method :builder_factory, :monosaccharide_factory

  def monosaccharide_factory(name)
    name.gsub!(/\{(\d+)\}/,'')
    hits = $1.to_i
    begin
      my_res = builder_factory(name)
    rescue Exception => e
      my_res = builder_factory('Nil')
      my_res.extend(ChameleonResidue)
      my_res.real_name = name
    end
    my_res.hits = hits || 0
    return my_res
  end
end

class RGB
  attr_accessor :r,:g,:b
  def initialize(r=0,g=0,b=0)
    @r = r
    @g = g
    @b = b
  end
  
  def to_hex
    return sprintf("#%02x%02x%02x",(@r*255).floor,(@g*255).floor,(@b*255).floor)
  end
end

class HSV
  attr_accessor :h,:s,:v
  def initialize(h=0,s=0,v=0)
    @h = h.to_f
    @s = s.to_f
    @v = v.to_f
  end
  
  def to_rgb
    sextant = (@h / 60).floor.modulo(6)
    f = (@h / 60.0) - sextant.to_f
    p = @v * (1 - @s)
    q = @v * (1 - f * @s)
    t = @v * (1 - (1 - f) * @s)
    case sextant
    when 0
      return RGB.new(@v,t,p)
    when 1
      return RGB.new(q,@v,p)
    when 2
      return RGB.new(p,@v,t)
    when 3
      return RGB.new(p,q,@v)
    when 4
      return RGB.new(t,p,@v)
    when 5
      return RGB.new(@v,p,q)
    end
  end
  def to_hex
    to_rgb.to_hex
  end
end

def render_hits_for_residue(residue,delta_occurence,parent_sugar)
  if @opts[:render_hits_for_all_residues] || residue.parent_sug == 'both'
  
    if residue.hits == 0
      return
    end
    residue.callbacks.push( lambda { |element|
      xcenter = -1*(residue.centre[:x]) 
      ycenter = -1*(residue.centre[:y])
      back = Element.new('svg:circle')
      back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 100, 'fill' => HSV.new(65 - (15+0.01*residue.normalised_hits*50),1,1).to_hex })
      delta_occurence.add_element(back)
    })
  else        
    # 'a' is 200 == Blue
    # 'b' is 125 == Green
    hue = (residue.parent_sug == 'a') ? 15 : 125
    residue.callbacks.push( lambda { |element|
      xcenter = -1*(residue.centre[:x]) 
      ycenter = -1*(residue.centre[:y])
      back = Element.new('svg:circle')
      back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 100, 'fill' => HSV.new(hue,1,1).to_hex })
      parent_sugar.add_element(back)
    })
  end
end

def render_sugar_with_coverage(sugar, filename)
    SugarHelper.MakeRenderable(sugar)  
    delta_occurence = Element.new('svg:g')
    sugar.underlays << delta_occurence
    parent_sugar = Element.new('svg:g')
    sugar.underlays << parent_sugar
    hits_labels = Element.new('svg:g')
    sugar.overlays << hits_labels
    sugar.residue_composition.each { |residue|


      if @opts[:label_hits_for_residues]
        residue.callbacks.push( lambda { |element|
          xcenter = -1*(residue.centre[:x] + 200 ) 
          ycenter = -1*(residue.centre[:y])
          label = Element.new('svg:text')
          label.add_attributes({'x' => xcenter, 'y' => ycenter, 'font-size' => 100, 'text-anchor' => 'middle' })
          label.text = "#{residue.hits}"
          hits_labels.add_element(label)
        })        
      end

      if @opts[:render_hit_outlines]
        if residue.hits == 0
          next
        end
        residue.callbacks.push( lambda { |element|
          xcenter = -1*(residue.centre[:x]) 
          ycenter = -1*(residue.centre[:y])
          back = Element.new('svg:circle')
          back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 100, 'fill'=>'none','stroke' => '#000000', 'stroke-width' => '1.0' })
          delta_occurence.add_element(back)
        })
        residue.children.each { |kid|
          link = kid[:link]
          link.callbacks.push( lambda { |link_element|
            x1 = -1*link.first_residue.centre[:x]
            y1 = -1*link.first_residue.centre[:y]
            x2 = -1*link.second_residue.centre[:x]
            y2 = -1*link.second_residue.centre[:y]
            link_width = (x2-x1).abs
            link_height = (y2-y1).abs
            link_length = Math.hypot(link_width,link_height)
            deltax = -1 * (100 * link_height / link_length).to_i
            deltay = (100 * link_width / link_length).to_i
            points = ""
            if y2 < y1
              points = "#{x1-deltax},#{y1+deltay} #{x2-deltax},#{y2+deltay} #{x2+deltax},#{y2-deltay} #{x1+deltax},#{y1-deltay}"
            else
              points = "#{x1+deltax},#{y1+deltay} #{x2+deltax},#{y2+deltay} #{x2-deltax},#{y2-deltay} #{x1-deltax},#{y1-deltay}"              
            end
            
            back = Element.new('svg:polygon')
            back.add_attributes({'points' => points, 'stroke'=>'#000000','fill'=>'none','stroke-width'=>'1.0'})
            delta_occurence.add_element(back)
          })
        }
        if @opts[:always_render_colours]
          render_hits_for_residue(residue,delta_occurence,parent_sugar)
        end
      else
        render_hits_for_residue(residue,delta_occurence,parent_sugar)
      end
    }

    unless @opts[:test]
      File.open(File.join(@opts[:output_directory],filename),"w") {|file|
        SugarHelper.RenderSugar(sugar,:full,@opts[:scheme],{ :padding => 200, :font_size => 50 }).write(file,4)
      }
    end

    sugar.overlays.delete(delta_occurence)
    sugar.overlays.delete(parent_sugar)    
    
end

seq_a = seq_b = nil

if opts[:use_unmatched]
  seq_a = glycomedb_unmatched_maps.assoc(opts[:key])[1]
  seq_b = (glycosuite_unmatched_maps.assoc(opts[:key]) || glycomedb_unmatched_maps.assoc(opts[:key]))[1]
else
  seq_a = glycomedb_maps.assoc(opts[:key])[1]
  seq_b = (glycosuite_maps.assoc(opts[:key]) || glycomedb_maps.assoc(opts[:key]))[1]
end

sug_a = nil
sug_b = nil
begin
  sug_a = SugarHelper.CreateMultiSugar(seq_a,:ic)
  sug_b = SugarHelper.CreateMultiSugar(seq_b,:ic)
rescue Exception => e
  puts e
end

[sug_a,sug_b].each { |sug|
  max_hits = sug.residue_composition.inject(0) { |max,r| [max,r.hits].max }
  sug.residue_composition.each {|r|
    r.delta_hits = 0
    r.normalised_hits = r.hits == 0 ? 0 : r.hits * 100.0 / max_hits 
    r.parent_sug = sug == sug_a ? 'a' : 'b'
  }
}
sug_a.union!(sug_b) { |res,other_res,already_matched|
  if res.equals?(other_res)
    res.parent_sug = 'both'
    if ( ! already_matched )
      res.delta_hits = (res.normalised_hits - other_res.normalised_hits).abs
    end
    res.hits = [ res.hits, other_res.hits ].max
    true    
  else
    false
  end
}

sug_a.leaves.each { |res|
  looper = res
  last_hits = 0  
  #(looper.hits >= last_hits) &&
  while ((looper.parent != nil) && looper.children.size < 1 ) do
      if looper.parent_sug == 'both'
        if (looper.hits > 0 && looper.delta_hits < opts[:min_delta_threshold])
          last_hits = looper.hits
          old_parent = looper.parent
          if ! sug_a.residue_composition.include?(old_parent)
            break
          end
          old_parent.remove_child(looper)
          looper = old_parent
          next
        end
        break
      end
      
      if opts[:normalised_hits_threshold] > 0 && looper.parent_sug != 'both'
        if looper.hits > 0 && looper.normalised_hits < opts[:normalised_hits_threshold]
          last_hits = looper.hits
          old_parent = looper.parent
          if ! sug_a.residue_composition.include?(old_parent)
            break
          end
          old_parent.remove_child(looper)
          looper = old_parent
          next
        end
        break
      end
      
      if looper.parent_sug == 'a'
        if opts[:delete_sug_a] || (looper.hits > 0 && looper.hits < opts[:sug_a_min_hits_threshold])
          last_hits = looper.hits
          old_parent = looper.parent
          if ! sug_a.residue_composition.include?(old_parent)
            break
          end
          old_parent.remove_child(looper)
          looper = old_parent
          next
        end
        break
      end

      if looper.parent_sug == 'b'
        if opts[:delete_sug_b] || (looper.hits > 0 && looper.hits < opts[:sug_b_min_hits_threshold])
          last_hits = looper.hits
          old_parent = looper.parent
          if ! sug_a.residue_composition.include?(looper.parent)
            break
          end
          old_parent.remove_child(looper)
          looper = old_parent
          next
        end        
        break
      end

      break

  end
}

sug_a.residue_composition.each { |res|
 if res.anomer == 'u' || res.paired_residue_position == 0
   res.parent.remove_child(res)
 end
}

SugarHelper.SetWriterType(sug_a,:ic)

def sug_a.write_residue(residue)
  if residue.parent_sug == 'both'
    return "{#{sprintf('%0.4f',residue.delta_hits)}}."
  end
  return "{#{sprintf('%0.4f',residue.hits)}#{residue.parent_sug}}#{residue.name(:ic)}"
end

puts sug_a.sequence
render_sugar_with_coverage(sug_a,"#{opts[:key]}.svg")