package org.ohdsi.featureExtraction;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Provides a function for computing the checksum of the current JAR file.
 * 
 * @author mschuemi
 *
 */
public class JarChecksum {
	
	/**
	 * Compute the checksum of the current JAR file. This can be used by R to verify that the JAR version is in sync with the R package. Note: will throw an
	 * error if not running from a JAR file.
	 * 
	 * @return The checksum of the current JAR file
	 */
	public static String computeJarChecksum() {
		File currentJavaJarFile = new File(JarChecksum.class.getProtectionDomain().getCodeSource().getLocation().getPath());
		String filepath = currentJavaJarFile.getAbsolutePath();
		StringBuilder checksum = new StringBuilder();
		try {
			MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
			FileInputStream fileInputStream = new FileInputStream(filepath);
			byte[] dataBytes = new byte[1024];
			int nread = 0;
			while ((nread = fileInputStream.read(dataBytes)) != -1)
				messageDigest.update(dataBytes, 0, nread);
			fileInputStream.close();
			byte[] mdBytes = messageDigest.digest();
			
			for (int i = 0; i < mdBytes.length; i++)
				checksum.append(Integer.toString((mdBytes[i] & 0xff) + 0x100, 16).substring(1));
		} catch (NoSuchAlgorithmException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return (checksum.toString());
	}
}
